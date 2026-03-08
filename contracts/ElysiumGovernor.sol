// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./CitizenshipNFT.sol";

/**
 * @title ElysiumGovernor
 * @dev Governor contract implementing 1-person-1-vote governance per Constitution v1.2
 * 
 * Voting Power: 1 vote per Citizenship NFT holder (Resident tier or higher)
 * Quorum: Tier1=10%, Tier2=25%, Tier3=40%
 * Majority: Simple=51%, Supermajority=67%, Core=80%
 */
contract ElysiumGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorTimelockControl, AccessControl {
    
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
    
    // Founder Veto Window (Constitution Article VIII)
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    uint48 public immutable deploymentTime;
    uint256 public constant VETO_WINDOW = 48 hours;
    uint256 public constant SUNSET_PERIOD = 3 * 365 days;
    
    // Veto tracking
    mapping(uint256 => bool) public proposalVetoed;
    
    // AI vote tracking (for cap enforcement)
    mapping(uint256 => uint256) private aiForVotes;
    mapping(uint256 => uint256) private aiAgainstVotes;
    // Note: AI abstentions not tracked (unlikely)
    
    // Events
    event ProposalTypeSet(uint256 indexed proposalId, ProposalType proposalType, Tier tier);
    event ProposalVetoed(uint256 indexed proposalId, address indexed founder, uint256 timestamp);
    
    constructor(
        CitizenshipNFT _citizenshipNFT,
        TimelockController _timelock,
        string memory name,
        address founder
    ) 
        Governor(name)
        GovernorSettings(1 days, 7 days, 0)  // votingDelay, votingPeriod, proposalThreshold
        GovernorTimelockControl(_timelock)
    {
        citizenshipNFT = _citizenshipNFT;
        deploymentTime = uint48(block.timestamp);
        _grantRole(FOUNDER_ROLE, founder);
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
        
        // Phase-based proposal restrictions (Constitution Article II.5 & IV.3)
        // Only H1 humans (phase == 1) may propose Constitutional amendments or Core Principle changes
        if (proposalType == ProposalType.Constitutional || proposalType == ProposalType.CorePrinciple) {
            require(!citizen.isAI, "Governor: AI cannot propose constitutional/core changes");
            require(citizen.phase == 1, "Governor: only H1 humans may propose this");
        }
        
        // AI phase check: AI may only propose in Phase 3? Actually Constitution says AI advisory only in Phase 1; Phase 2 they can propose? It says Phase 2: 0.5x vote weight on technical matters only; doesn't mention proposing. Likely AI can propose in Phase 2+? For now, allow any phase >=2? Simpler: allow AI to propose any, but voting weight will be limited.
        
        // Determine tier from proposal type
        // AI proposal restrictions: only technical proposals (ParameterChange) in Phase 1/2
        if (citizen.isAI) {
            if (citizen.phase == 1 || citizen.phase == 2) {
                require(proposalType == ProposalType.ParameterChange, "Governor: AI may only propose technical parameters");
            }
        }
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
     * @dev Founder veto: veto a queued proposal within 48 hours of execution
     * Only callable by FOUNDER_ROLE, and only within 3 years of deployment
     * Constitution Article VIII: Founder Veto Window
     */
    function vetoProposal(uint256 proposalId) external onlyRole(FOUNDER_ROLE) {
        // Check proposal is queued (waiting for execution)
        require(state(proposalId) == ProposalState.Queued, "Governor: proposal not queued");
        
        // Get proposal eta (execution time)
        uint256 eta = proposalEta(proposalId);
        require(eta > 0, "Governor: proposal has no eta");
        
        // Ensure within 3-year sunset period from deployment (check first)
        require(
            block.timestamp < deploymentTime + SUNSET_PERIOD,
            "Governor: veto window has sunset"
        );
        
        // Ensure within 48-hour window before execution
        // Must be before eta
        require(block.timestamp < eta, "Governor: veto only allowed within 48h of execution");
        // And within VETO_WINDOW of eta (now safe because block.timestamp < eta)
        require(eta - block.timestamp <= VETO_WINDOW, "Governor: veto only allowed within 48h of execution");
        
        // Check not already vetoed
        require(!proposalVetoed[proposalId], "Governor: proposal already vetoed");
        
        proposalVetoed[proposalId] = true;
        emit ProposalVetoed(proposalId, msg.sender, block.timestamp);
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
     * 
     * Phase interpretation:
     * - Humans: phase 1=H1, 2=H2, 3=H3 (H3 may have voting delay - NOT ENFORCED YET)
     * - AI: phase 1=Phase1 (advisory, no vote), phase 2=Phase2 (0.5x on technical), phase 3=Phase3 (full)
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
        
        // H3 6-month voting delay: Human phase 3 must have held citizenship for at least 6 months (183 days)
        if (!citizen.isAI && citizen.phase == 3 && block.timestamp < citizen.createdAt + 183 days) {
            return 0;
        }

        // AI voting rights per phase (Constitution Article IX)
        if (citizen.isAI) {
            if (citizen.phase == 1) {
                // Phase 1: Advisory only, no voting
                return 0;
            } else if (citizen.phase == 2) {
                // Phase 2: 0.5x weight (50%) on technical matters only, capped at 20% of total votes
                return (1 ether * 5000) / 10000; // 0.5x
            } else if (citizen.phase >= 3) {
                // Phase 3: Full equality
                return 1 ether;
            } else {
                return 0;
            }
        }
        
        // Human citizens (H1, H2, and H3 with >=6 months tenure): 1 vote each
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
    
    /**
     * @dev Determine if a proposal succeeds based on votes and proposal type
     * Thresholds (basis points of total votes cast):
     * - Simple/Parameter: >50% (simple majority)
     * - TreasurySpendSmall (<10k): 51% majority
     * - TreasurySpendMedium (10k-1M): 60% majority
     * - TreasurySpendLarge (>1M): 67% majority
     * - Constitutional: 67% majority
     * - CorePrinciple: 80% majority
     * - AIPhaseTransition: 67% majority
     * - MultiSigElection: 51% majority
     * Note: Quorum is checked separately via _quorumReached.
     */
    /**
     * @dev Override to track AI votes separately and enforce AI Phase 2 technical voting restriction.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual override(Governor, GovernorCountingSimple) {
        // Check if voter is AI and track for AI cap
        uint256 tokenId = citizenshipNFT.citizenTokenId(account);
        if (tokenId > 0) {
            CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
            if (citizen.isAI && citizen.phase >= 2) {
                // AI Phase 2 can only vote on technical proposals (ParameterChange)
                if (citizen.phase == 2) {
                    ProposalType pType = proposalTypes[proposalId];
                    require(pType == ProposalType.ParameterChange, "Governor: AI Phase 2 only technical");
                }
                // Record AI votes separately (for/against; ignore abstain)
                if (support == 1) {
                    aiForVotes[proposalId] += weight;
                } else if (support == 0) {
                    aiAgainstVotes[proposalId] += weight;
                }
            }
        }
        // Continue with standard counting
        super._countVote(proposalId, account, support, weight, params);
    }

    /**
     * @dev Apply AI vote cap (20% of total votes) to get effective vote counts.
     */
    function _applyAICap(
        uint256 forVotes,
        uint256 againstVotes,
        uint256 aiFor,
        uint256 aiAgainst
    ) internal pure returns (uint256 effectiveFor, uint256 effectiveAgainst) {
        if (aiFor == 0 && aiAgainst == 0) {
            return (forVotes, againstVotes);
        }
        uint256 total = forVotes + againstVotes;
        uint256 aiTotal = aiFor + aiAgainst;
        uint256 aiCap = (total * 20) / 10000; // 20% cap
        if (aiTotal <= aiCap) {
            return (forVotes, againstVotes);
        }
        // Scale down AI votes proportionally
        uint256 scaledAiFor = (aiFor * aiCap) / aiTotal;
        uint256 scaledAiAgainst = (aiAgainst * aiCap) / aiTotal;
        effectiveFor = (forVotes - aiFor) + scaledAiFor;
        effectiveAgainst = (againstVotes - aiAgainst) + scaledAiAgainst;
    }

    function _voteSucceeded(uint256 proposalId) internal view virtual override(Governor, GovernorCountingSimple) returns (bool) {
        ProposalType proposalType = proposalTypes[proposalId];
        (uint256 againstVotes, uint256 forVotes, ) = proposalVotes(proposalId);
        uint256 aiFor = aiForVotes[proposalId];
        uint256 aiAgainst = aiAgainstVotes[proposalId];

        (uint256 effectiveFor, uint256 effectiveAgainst) = _applyAICap(forVotes, againstVotes, aiFor, aiAgainst);
        uint256 effectiveTotal = effectiveFor + effectiveAgainst;
        if (effectiveTotal == 0) {
            return false;
        }

        uint256 numerator = effectiveFor * 10000;
        uint256 requiredPercentage;

        if (proposalType == ProposalType.CorePrinciple) {
            requiredPercentage = 8000; // 80%
        } else if (proposalType == ProposalType.Constitutional || 
                   proposalType == ProposalType.TreasurySpendLarge ||
                   proposalType == ProposalType.AIPhaseTransition) {
            requiredPercentage = 6700; // 67%
        } else if (proposalType == ProposalType.TreasurySpendMedium) {
            requiredPercentage = 6000; // 60%
        } else {
            // Simple majority: >50%
            return effectiveFor > effectiveAgainst;
        }

        return numerator >= effectiveTotal * requiredPercentage;
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
        require(!proposalVetoed[proposalId], "Governor: proposal vetoed");
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
    
    
    /**
     * @dev Support interfaces (required for AccessControl + Governor)
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
