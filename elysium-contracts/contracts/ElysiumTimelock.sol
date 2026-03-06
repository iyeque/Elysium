// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title ElysiumTimelock
 * @dev Timelock controller for Elysium governance with constitution-compliant delays
 * 
 * Delays per Consultation Protocol v1.1:
 * - Tier 1 proposals: 24 hours minimum
 * - Tier 2 proposals: 72 hours minimum  
 * - Tier 3 proposals: 7 days minimum
 * 
 * Roles:
 * - TIMELOCK_ADMIN_ROLE: Can grant/revoke other roles (held by Governor)
 * - PROPOSER_ROLE: Can queue operations (held by Governor)
 * - EXECUTOR_ROLE: Can execute operations (held by Governor or multi-sig)
 * - CANCELLER_ROLE: Can cancel proposals (held by Governor)
 */
contract ElysiumTimelock is TimelockController {
    
    // Constitution-mandated minimum delays
    uint256 public constant MIN_DELAY_TIER1 = 1 days;
    uint256 public constant MIN_DELAY_TIER2 = 3 days;
    uint256 public constant MIN_DELAY_TIER3 = 7 days;
    
    // Emergency pause multi-sig (can cancel in emergencies)
    address public pauseMultiSig;
    
    event PauseMultiSigUpdated(address indexed newPauseMultiSig);
    
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {
        // Admin should be the Governor contract
        // Proposers and executors are typically the Governor
    }
    
    /**
     * @dev Set the pause multi-sig address (emergency cancellation authority)
     * Per Constitution: Pause Multi-Sig (2/3 H1/H2) can emergency pause for max 48h
     */
    function setPauseMultiSig(address _pauseMultiSig) external onlyRole(keccak256("TIMELOCK_ADMIN_ROLE")) {
        pauseMultiSig = _pauseMultiSig;
        emit PauseMultiSigUpdated(_pauseMultiSig);
    }
    
    /**
     * @dev Check if a proposal meets the minimum delay for its tier
     * This is a view function for validation before queuing
     */
    function validateDelayForTier(
        uint256 delay,
        uint256 tier
    ) external pure returns (bool) {
        if (tier == 0) { // Tier 1
            return delay >= MIN_DELAY_TIER1;
        } else if (tier == 1) { // Tier 2
            return delay >= MIN_DELAY_TIER2;
        } else { // Tier 3
            return delay >= MIN_DELAY_TIER3;
        }
    }
}
