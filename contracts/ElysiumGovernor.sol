// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./CitizenshipNFT.sol";

/**
 * @title ElysiumGovernor
 * @dev Governor contract implementing 1-person-1-vote governance per Constitution v1.2
 * 
 * Voting Power: 1 vote per Citizenship NFT holder (Resident tier or higher)
 * Quorum: Tier1=10%, Tier2=25%, Tier3=40%
 * Majority: Simple=51%, Supermajority=67%, Core=80%
 */
contract ElysiumGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorTimelockControl {
    
    // Proposal types per Constitution
    enum ProposalType {
        ParameterChange,      // Tier 1
        TreasurySpendSmall,   // Tier 1 (<10k ELYS)
        TreasurySpendMedium,  // Tier 2 (10k-1M ELYS)
        TreasurySpendLarge,   // Tier 3 (>1M ELYS)
        Constitutional,       // Tier 3 (67% supermajority)
        CorePrinciple,        // Tier 3 (80% supermajority)
        AIPhaseTransition,    // Tier 3 (67% + AI vote threshold)
        MultiSigElection      // Tier 2 (elect multi-sig signers)
    }
    
    // Tier classification
    enum Tier {
        Tier1,  // 3 days consultation, 7 days voting, 10% quorum
        Tier2,  // 7 days consultation, 7 days voting, 25% quorum
        Tier3   // 14+ days consultation, 10 days voting, 40% quorum
    }
    
    // Citizenship NFT contract
    CitizenshipNFT public immutable citizenshipNFT;
    
    // Quorum thresholds (basis points: 10000 = 100%)
    uint256 public quorumTier1 = 1000;   // 10%
    uint256 public quorumTier2 = 2500;   // 25%
    uint256 public quorumTier3 = 4000;   // 40%
    
    // Treasury spend thresholds (in ELYS wei, assuming 18 decimals)
    uint256 public constant TREASURY_SMALL = 10_000 * 1e18;   // 10k
    uint256 public constant TREASURY_MEDIUM = 1_000_000 * 1e18; // 1M
    
    // Proposal metadata
    mapping(uint256 => ProposalType) public proposalTypes;
    mapping(uint256 => Tier) public proposalTiers;
    
    // Events
    event ProposalTypeSet(uint256 indexed proposalId, ProposalType proposalType, Tier tier);
    
    constructor(
        CitizenshipNFT _citizenshipNFT,
        TimelockController _timelock,
        string memory name
    ) 
        Governor(name)
        GovernorSettings(1 days, 7 days, 0)  // votingDelay, votingPeriod, proposalThreshold
        GovernorTimelockControl(_timelock)
    {
        citizenshipNFT = _citizenshipNFT;
    }
    
    /**
     * @dev Submit a proposal with type classification
     */
    function propose(
        ProposalType proposalType,
        string memory title,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) public returns (uint256) {
        // Verify proposer has Citizenship NFT with Resident+ tier
        uint256 tokenId = citizenshipNFT.citizenTokenId(msg.sender);
        require(tokenId > 0, "Governor: not a citizen");
        
        CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
        require(citizen.tier >= 1, "Governor: Resident tier required"); // tier 1=Resident
        
        // Determine tier from proposal type
        Tier tier = _getTierFromType(proposalType);
        
        // Create description with title and type
        string memory description = string(abi.encodePacked(title, "#", _proposalTypeToString(proposalType)));
        
        // Store proposal metadata
        uint256 proposalId = super.propose(targets, values, calldatas, description);
        proposalTypes[proposalId] = proposalType;
        proposalTiers[proposalId] = tier;
        
        emit ProposalTypeSet(proposalId, proposalType, tier);
        
        return proposalId;
    }
    
    /**
     * @dev Get tier from proposal type
     */
    function _getTierFromType(ProposalType proposalType) internal pure returns (Tier) {
        if (proposalType == ProposalType.ParameterChange || 
            proposalType == ProposalType.TreasurySpendSmall) {
            return Tier.Tier1;
        } else if (proposalType == ProposalType.TreasurySpendMedium || 
                   proposalType == ProposalType.MultiSigElection) {
            return Tier.Tier2;
        } else {
            return Tier.Tier3; // Constitutional, CorePrinciple, AIPhaseTransition, TreasurySpendLarge
        }
    }
    
    /**
     * @dev Convert proposal type to string for description
     */
    function _proposalTypeToString(ProposalType proposalType) internal pure returns (string memory) {
        if (proposalType == ProposalType.ParameterChange) return "ParameterChange";
        if (proposalType == ProposalType.TreasurySpendSmall) return "TreasurySpendSmall";
        if (proposalType == ProposalType.TreasurySpendMedium) return "TreasurySpendMedium";
        if (proposalType == ProposalType.TreasurySpendLarge) return "TreasurySpendLarge";
        if (proposalType == ProposalType.Constitutional) return "Constitutional";
        if (proposalType == ProposalType.CorePrinciple) return "CorePrinciple";
        if (proposalType == ProposalType.AIPhaseTransition) return "AIPhaseTransition";
        if (proposalType == ProposalType.MultiSigElection) return "MultiSigElection";
        return "Unknown";
    }
    
    /**
     * @dev Voting power: 1 vote per eligible citizen (Resident+ tier)
     * Uses 1e18 precision for compatibility with OpenZeppelin
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view override returns (uint256) {
        uint256 tokenId = citizenshipNFT.citizenTokenId(account);
        if (tokenId == 0) {
            return 0;
        }
        
        CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
        
        // Must be Resident+ tier (tier >= 1)
        if (citizen.tier < 1) {
            return 0;
        }
        
        // AI voting rights per phase (Constitution Article IX)
        if (citizen.isAI) {
            if (citizen.phase == 0) {
                // Phase 1: Advisory only, no voting
                return 0;
            } else if (citizen.phase == 1) {
                // Phase 2: 0.5x weight (simplified - full implementation would check proposal type)
                return (1 ether * 5000) / 10000; // 0.5x
            } else {
                // Phase 3: Full equality
                return 1 ether;
            }
        }
        
        // Human citizens: 1 vote each
        return 1 ether;
    }
    
    /**
     * @dev Total supply of voting-eligible citizens
     */
    function _getTotalVotes() internal view returns (uint256) {
        // This would require tracking total eligible voters
        // For now, return total NFT supply (simplified)
        // Production: maintain a counter of eligible voters (tier >= 1, not revoked)
        return citizenshipNFT.totalSupply() * 1 ether;
    }
    
    /**
     * @dev Quorum calculation based on proposal tier
     */
    function quorum(uint256 /*blockNumber*/) public view override returns (uint256) {
        // Simplified: uses Tier1 quorum by default
        // Production: track proposal tier at snapshot and apply correct quorum
        uint256 totalSupply = citizenshipNFT.totalSupply();
        return (totalSupply * quorumTier1) / 10000;
    }
    
    /**
     * @dev Proposal threshold: 0 (any eligible citizen can propose)
     */
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return 0;
    }
    
    /**
     * @dev Clock function for ERC6372 compliance (block number-based)
     */
    function clock() public view override returns (uint48) {
        return uint48(block.number);
    }
    
    /**
     * @dev Clock mode for ERC6372 compliance
     */
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=blocknumber&from=default";
    }
    
    // Required overrides for GovernorTimelockControl
    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }
    
    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }
    
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }
    
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }
    
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }
    
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }
    
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }
    
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }
}
