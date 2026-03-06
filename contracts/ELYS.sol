// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IStakingRewards {
    function addRewards(uint256 amount) external;
}

contract ELYS is ERC20, AccessControl {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public constant FEE_BPS = 10; // 0.1% = 10 bps

    address public rewardsPool;

    event FeesCollected(address indexed from, address indexed to, uint256 amount, uint256 burnAmount, uint256 rewardAmount);
    event RewardsPoolSet(address indexed pool);

    constructor(address _rewardsPool) ERC20("Elysium", "ELYS") {
        _mint(msg.sender, MAX_SUPPLY);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        rewardsPool = _rewardsPool;
        emit RewardsPoolSet(_rewardsPool);
    }

    function setRewardsPool(address _pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardsPool = _pool;
        emit RewardsPoolSet(_pool);
    }

    // Stub for Governor compatibility (returns current balance)
    function getPriorVotes(address account, uint256) public view returns (uint256) {
        return balanceOf(account);
    }

    function _update(address from, address to, uint256 amount) internal virtual override {
        // No fee on mint/burn, and no fee if rewardsPool not set
        if (rewardsPool != address(0) && from != address(0) && to != address(0)) {
            uint256 fee = (amount * FEE_BPS) / 10000;
            if (fee > 0) {
                uint256 burnAmount = fee / 2; // 50% burn
                uint256 rewardAmount = fee - burnAmount;
                uint256 netAmount = amount - fee;

                // Transfer net amount to recipient
                super._update(from, to, netAmount);

                // Burn half
                if (burnAmount > 0) {
                    super._update(from, address(0), burnAmount);
                }

                // Send reward portion to staking pool and notify
                if (rewardAmount > 0) {
                    super._update(from, rewardsPool, rewardAmount);
                    // Notify Staking contract to account for new rewards
                    try IStakingRewards(rewardsPool).addRewards(rewardAmount) {} catch {}
                }

                emit FeesCollected(from, to, amount, burnAmount, rewardAmount);
                return;
            }
        }
        super._update(from, to, amount);
    }
}
