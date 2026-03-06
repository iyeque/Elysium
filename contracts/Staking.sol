// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import { ELYS } from "./ELYS.sol";
import { CitizenshipNFT } from "./CitizenshipNFT.sol";

contract Staking is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for ELYS;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");

    ELYS public token;
    CitizenshipNFT public citizenshipNft;

    uint256 public constant STAKE_LOCK_DURATION = 30 days;
    uint256 public constant UNSTAKE_DELAY = 30 days;
    uint256 public constant MIN_CITIZENSHIP_STAKE = 10_000 * 10**18;

    struct Stake {
        uint256 amount;
        uint256 stakedAt;
        uint256 unlockTime;
        uint256 withdrawTime;
        bool withdrawn;
    }

    mapping(address => mapping(uint256 => Stake)) public stakes;
    mapping(address => uint256) public totalStaked; // per-user total
    uint256 public globalTotalStaked; // sum of all stakes
    mapping(address => uint256) public nextStakeId;
    mapping(address => uint256) public citizenshipStakeId;

    // Reward distribution
    uint256 public rewardPerToken = 0; // Accumulated reward per token, scaled by 1e18
    uint256 public pendingRewards; // Rewards accumulated when totalStaked == 0
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public unclaimedRewards;

    event Staked(address indexed user, uint256 stakeId, uint256 amount, uint256 unlockTime);
    event UnstakeRequested(address indexed user, uint256 stakeId, uint256 withdrawTime);
    event Withdrawn(address indexed user, uint256 stakeId, uint256 amount);
    event CitizenshipMinted(address indexed user, uint256 tokenId, uint256 stakeId);
    event RewardsAdded(uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _token, address _citizenshipNft) {
        token = ELYS(_token);
        citizenshipNft = CitizenshipNFT(_citizenshipNft);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(REWARDER_ROLE, msg.sender);
    }

    function addRewards(uint256 amount) external onlyRole(REWARDER_ROLE) {
        require(amount > 0, "Staking: zero rewards");
        if (globalTotalStaked == 0) {
            pendingRewards += amount;
        } else {
            rewardPerToken += (amount * 1e18) / globalTotalStaked;
        }
        emit RewardsAdded(amount);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Staking: amount zero");
        require(amount % 1 ether == 0, "Staking: amount must be whole tokens");
        uint256 stakeId = nextStakeId[msg.sender]++;
        uint256 currentTime = block.timestamp;

        // Update rewards for user before changing stake
        _updateRewards(msg.sender);

        // If this is the first stake and there are pending rewards, incorporate them
        if (globalTotalStaked == 0 && pendingRewards > 0) {
            uint256 newTotal = globalTotalStaked + amount;
            rewardPerToken += (pendingRewards * 1e18) / newTotal;
            pendingRewards = 0;
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        stakes[msg.sender][stakeId] = Stake({
            amount: amount,
            stakedAt: currentTime,
            unlockTime: currentTime + STAKE_LOCK_DURATION,
            withdrawTime: 0,
            withdrawn: false
        });
        totalStaked[msg.sender] += amount;
        globalTotalStaked += amount;

        if (totalStaked[msg.sender] >= MIN_CITIZENSHIP_STAKE && citizenshipStakeId[msg.sender] == 0) {
            _mintCitizenship(msg.sender);
        }
        emit Staked(msg.sender, stakeId, amount, currentTime + STAKE_LOCK_DURATION);
    }

    function requestUnstake(uint256 stakeId) external nonReentrant whenNotPaused {
        Stake storage stk = stakes[msg.sender][stakeId];
        require(stk.amount > 0, "Staking: no stake");
        require(!stk.withdrawn, "Staking: already withdrawn");
        require(block.timestamp >= stk.unlockTime, "Staking: still locked");

        // Update rewards before changing stake
        _updateRewards(msg.sender);

        uint256 withdrawTime = block.timestamp + UNSTAKE_DELAY;
        stk.withdrawTime = withdrawTime;
        emit UnstakeRequested(msg.sender, stakeId, withdrawTime);
    }

    function withdraw(uint256 stakeId) external nonReentrant whenNotPaused {
        Stake storage stk = stakes[msg.sender][stakeId];
        require(stk.amount > 0, "Staking: no stake");
        require(!stk.withdrawn, "Staking: already withdrawn");
        require(block.timestamp >= stk.withdrawTime, "Staking: unstake delay not complete");

        // Update rewards before removing stake
        _updateRewards(msg.sender);

        uint256 amount = stk.amount;
        stk.withdrawn = true;
        totalStaked[msg.sender] -= amount;
        globalTotalStaked -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, stakeId, amount);
    }

    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);
        uint256 reward = unclaimedRewards[msg.sender];
        require(reward > 0, "Staking: no rewards");
        unclaimedRewards[msg.sender] = 0;
        token.safeTransfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function balanceOf(address user) external view returns (uint256) {
        return totalStaked[user];
    }

    function getLockTimeRemaining(address user, uint256 stakeId) external view returns (uint256) {
        Stake memory stk = stakes[user][stakeId];
        if (stk.amount == 0 || stk.withdrawn) return 0;
        if (block.timestamp < stk.unlockTime) return stk.unlockTime - block.timestamp;
        return 0;
    }

    function getUnstakeDelayRemaining(address user, uint256 stakeId) external view returns (uint256) {
        Stake memory stk = stakes[user][stakeId];
        if (stk.amount == 0 || stk.withdrawTime == 0) return 0;
        if (block.timestamp < stk.withdrawTime) return stk.withdrawTime - block.timestamp;
        return 0;
    }

    function _updateRewards(address user) internal {
        if (globalTotalStaked > 0 && totalStaked[user] > 0 && rewardPerToken > userRewardPerTokenPaid[user]) {
            uint256 owed = (totalStaked[user] * (rewardPerToken - userRewardPerTokenPaid[user])) / 1e18;
            unclaimedRewards[user] += owed;
        }
        userRewardPerTokenPaid[user] = rewardPerToken;
    }

    function _mintCitizenship(address user) internal {
        uint256 firstStakeId = nextStakeId[user] - 1;
        citizenshipStakeId[user] = firstStakeId;
        uint256 tier = _calculateTier(totalStaked[user]);
        uint256 phase = 3; // H3 - Stake-based residency (per Constitution Article II.5)
        uint256 tokenId = citizenshipNft.mintHuman(user, tier, phase, "");
        emit CitizenshipMinted(user, tokenId, firstStakeId);
    }

    function _calculateTier(uint256 stakeAmount) internal pure returns (uint256) {
        if (stakeAmount >= 100_000 * 1e18) return 3; // Founder
        if (stakeAmount >= 10_000 * 1e18) return 2;  // Citizen
        if (stakeAmount >= 1_000 * 1e18) return 1;   // Resident
        return 0; // Observer (no governance rights)
    }

    function updateTier(address user) external {
        uint256 tokenId = citizenshipNft.citizenTokenId(user);
        require(tokenId > 0, "Staking: no citizenship");
        uint256 newTier = _calculateTier(totalStaked[user]);
        citizenshipNft.updateTier(tokenId, newTier);
    }
}
