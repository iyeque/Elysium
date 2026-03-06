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
       mapping(address => uint256) public totalStaked;
       mapping(address => uint256) public nextStakeId;
       mapping(address => uint256) public citizenshipStakeId;

       event Staked(address indexed user, uint256 stakeId, uint256 amount, uint256 unlockTime);
       event UnstakeRequested(address indexed user, uint256 stakeId, uint256 withdrawTime);
       event Withdrawn(address indexed user, uint256 stakeId, uint256 amount);
       event CitizenshipMinted(address indexed user, uint256 tokenId, uint256 stakeId);

       constructor(address _token, address _citizenshipNft) {
           token = ELYS(_token);
           citizenshipNft = CitizenshipNFT(_citizenshipNft);
           _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
           _grantRole(PAUSER_ROLE, msg.sender);
           _grantRole(MINTER_ROLE, msg.sender);
       }

       function stake(uint256 amount) external nonReentrant whenNotPaused {
           require(amount > 0, "Staking: amount zero");
           require(amount % 1 ether == 0, "Staking: amount must be whole tokens");
           uint256 stakeId = nextStakeId[msg.sender]++;
           uint256 currentTime = block.timestamp;
           token.safeTransferFrom(msg.sender, address(this), amount);
           stakes[msg.sender][stakeId] = Stake({
               amount: amount,
               stakedAt: currentTime,
               unlockTime: currentTime + STAKE_LOCK_DURATION,
               withdrawTime: 0,
               withdrawn: false
           });
           totalStaked[msg.sender] += amount;
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
           uint256 withdrawTime = block.timestamp + UNSTAKE_DELAY;
           stk.withdrawTime = withdrawTime;
           emit UnstakeRequested(msg.sender, stakeId, withdrawTime);
       }

       function withdraw(uint256 stakeId) external nonReentrant whenNotPaused {
           Stake storage stk = stakes[msg.sender][stakeId];
           require(stk.amount > 0, "Staking: no stake");
           require(!stk.withdrawn, "Staking: already withdrawn");
           require(block.timestamp >= stk.withdrawTime, "Staking: unstake delay not complete");
           uint256 amount = stk.amount;
           stk.withdrawn = true;
           totalStaked[msg.sender] -= amount;
           token.safeTransfer(msg.sender, amount);
           emit Withdrawn(msg.sender, stakeId, amount);
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

       function _mintCitizenship(address user) internal {
           uint256 firstStakeId = nextStakeId[user] - 1;
           citizenshipStakeId[user] = firstStakeId;
           uint256 tier = _calculateTier(totalStaked[user]);
           uint256 phase = 0; // Default unverified; update after verification (H1/H2/H3)
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