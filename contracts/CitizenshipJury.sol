// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./CitizenshipNFT.sol";

contract CitizenshipJury is ReentrancyGuard, AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant REQUIRED_SIGNATURES = 3;
    uint256 private constant MAX_SIGNERS = 5;

    // ELYS token for challenge deposits
    IERC20 public elys;
    uint256 public constant CHALLENGE_DEPOSIT = 1000 * 1e18; // 1000 ELYS
    uint256 public constant H1_CHALLENGE_DEPOSIT = 0; // H1 exempt from deposit
    uint256 public constant MAX_CHALLENGES_PER_30_DAYS = 3;
    uint256 public constant CHALLENGE_WINDOW = 30 days;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Challenge rate limiting: track challenge timestamps per address
    mapping(address => uint256[]) public challengeTimestamps; // challenger -> array of challenge timestamps

    // Challenge data
    struct Challenge {
        uint256 tokenId;
        address challenger;
        uint256 deposit;
        uint256 createdAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    uint256 public nextChallengeId = 1;
    mapping(uint256 => Challenge) public challenges; // challengeId -> Challenge
    mapping(uint256 => uint256) public tokenIdToChallengeId; // active challenge per token
    mapping(uint256 => mapping(address => bool)) public voted; // challengeId -> voter
    mapping(uint256 => address[]) public challengeJurors; // challengeId -> selected juror addresses

    // Existing multisig fields
    struct Transaction {
        uint256 value;
        address to;
        bytes data;
        bool executed;
        uint256 approvals;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(address => bool) public isSigner;
    uint256 public nextTransactionId = 1;

    CitizenshipNFT public immutable citizenshipNFT;

    // Events for challenges
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed tokenId, address indexed challenger, address[] jurors);
    event VoteCast(uint256 indexed challengeId, address indexed juror, bool support);
    event ChallengeExecuted(uint256 indexed challengeId, bool revoked);

    // Existing events
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event TransactionConfirmed(uint256 indexed txId, address indexed confirmer);
    event TransactionExecuted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionCancelled(uint256 indexed txId);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    constructor(address[] memory _initialSigners, address _admin, address _citizenshipNft, address _elys) {
        require(_initialSigners.length <= MAX_SIGNERS, "CitizenshipJury: too many signers");
        require(_initialSigners.length >= REQUIRED_SIGNATURES, "CitizenshipJury: too few signers");
        citizenshipNFT = CitizenshipNFT(_citizenshipNft);
        elys = IERC20(_elys);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        for (uint256 i = 0; i < _initialSigners.length; i++) {
            _addSigner(_initialSigners[i]);
        }
    }

    // --- Existing multisig functions (unchanged) ---

    function _checkEligibility(address signer) internal view returns (bool) {
        uint256 tokenId = citizenshipNFT.citizenTokenId(signer);
        if (tokenId == 0) return false;
        CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
        if (citizen.isAI) return false;
        if (citizen.tier < 2) return false; // at least Citizen tier
        // H1 or H2 (phase 1 or 2) only; H3 excluded
        if (citizen.phase != 1 && citizen.phase != 2) return false;
        return true;
    }

    function _addSigner(address signer) internal {
        require(!isSigner[signer], "CitizenshipJury: already a signer");
        require(_checkEligibility(signer), "CitizenshipJury: ineligible signer");
        _grantRole(SIGNER_ROLE, signer);
        isSigner[signer] = true;
        emit SignerAdded(signer);
    }

    function _removeSigner(address signer) internal {
        require(isSigner[signer], "CitizenshipJury: not a signer");
        _revokeRole(SIGNER_ROLE, signer);
        isSigner[signer] = false;
    }

    function addSigner(address signer) external onlyRole(ADMIN_ROLE) {
        _addSigner(signer);
    }

    function removeSigner(address signer) external onlyRole(ADMIN_ROLE) {
        _removeSigner(signer);
    }

    function submitTransaction(address to, uint256 value, bytes calldata data) external onlyRole(SIGNER_ROLE) {
        require(_checkEligibility(msg.sender), "CitizenshipJury: H3 cannot serve");
        require(to != address(0) || value > 0 || data.length > 0, "CitizenshipJury: invalid transaction");
        uint256 txId = nextTransactionId++;
        transactions[txId] = Transaction({
            value: value,
            to: to,
            data: data,
            executed: false,
            approvals: 0
        });
        isConfirmed[txId][msg.sender] = true;
        transactions[txId].approvals += 1;
        emit TransactionSubmitted(txId, to, value, data);
        emit TransactionConfirmed(txId, msg.sender);
    }

    function confirmTransaction(uint256 txId) external onlyRole(SIGNER_ROLE) {
        require(_checkEligibility(msg.sender), "CitizenshipJury: H3 cannot serve");
        Transaction storage txn = transactions[txId];
        require(txn.value > 0 || txn.to != address(0) || txn.data.length > 0, "CitizenshipJury: invalid transaction");
        require(!txn.executed, "CitizenshipJury: already executed");
        require(!isConfirmed[txId][msg.sender], "CitizenshipJury: already confirmed");
        isConfirmed[txId][msg.sender] = true;
        txn.approvals += 1;
        emit TransactionConfirmed(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external nonReentrant onlyRole(SIGNER_ROLE) {
        require(_checkEligibility(msg.sender), "CitizenshipJury: H3 cannot serve");
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "CitizenshipJury: already executed");
        require(txn.approvals >= REQUIRED_SIGNATURES, "CitizenshipJury: not enough confirmations");
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "CitizenshipJury: execution failed");
        txn.executed = true;
        emit TransactionExecuted(txId, txn.to, txn.value);
    }

    function cancelTransaction(uint256 txId) external onlyRole(ADMIN_ROLE) {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "CitizenshipJury: already executed");
        delete transactions[txId];
        emit TransactionCancelled(txId);
    }

    receive() external payable {}
    fallback() external payable {}

    // --- Identity Challenge System ---

    /**
     * @dev Check if challenger is eligible and return required deposit.
     * H3 and AI cannot challenge. H1 is exempt from deposit.
     */
    function _checkChallengerEligibility(address challenger) internal view returns (uint256 deposit) {
        uint256 tokenId = citizenshipNFT.citizenTokenId(challenger);
        require(tokenId > 0, "CitizenshipJury: challenger not a citizen");
        
        CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
        
        // AI cannot challenge
        require(!citizen.isAI, "CitizenshipJury: AI cannot challenge");
        
        // H3 (phase 3) cannot challenge
        require(citizen.phase != 3, "CitizenshipJury: H3 cannot challenge");
        
        // Check rate limit: max 3 challenges per 30 days
        uint256[] memory timestamps = challengeTimestamps[challenger];
        uint256 recentCount = 0;
        // Use unchecked subtraction to avoid underflow when block.timestamp < CHALLENGE_WINDOW
        uint256 windowStart = block.timestamp > CHALLENGE_WINDOW ? block.timestamp - CHALLENGE_WINDOW : 0;
        for (uint256 i = 0; i < timestamps.length; i++) {
            if (timestamps[i] > windowStart) {
                recentCount++;
            }
        }
        require(recentCount < MAX_CHALLENGES_PER_30_DAYS, "CitizenshipJury: challenge limit reached");
        
        // H1 (tier 2, phase 1) is exempt from deposit
        if (citizen.tier == 2 && citizen.phase == 1) {
            return 0;
        }
        
        // H2 (tier 2, phase 2) must pay deposit
        return CHALLENGE_DEPOSIT;
    }

    function createChallenge(uint256 tokenId) external nonReentrant {
        require(tokenId > 0, "CitizenshipJury: invalid token");
        CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
        require(citizen.wallet != address(0), "CitizenshipJury: not a citizen");
        require(tokenIdToChallengeId[tokenId] == 0, "CitizenshipJury: already challenged");
        
        // Check challenger eligibility and get required deposit
        uint256 requiredDeposit = _checkChallengerEligibility(msg.sender);
        
        // Transfer deposit if required
        if (requiredDeposit > 0) {
            require(elys.transferFrom(msg.sender, address(this), requiredDeposit), "CitizenshipJury: deposit transfer failed");
        }

        uint256 challengeId = nextChallengeId++;
        Challenge storage c = challenges[challengeId];
        c.tokenId = tokenId;
        c.challenger = msg.sender;
        c.deposit = requiredDeposit;
        c.createdAt = block.timestamp;
        c.votesFor = 0;
        c.votesAgainst = 0;
        c.executed = false;

        tokenIdToChallengeId[tokenId] = challengeId;
        
        // Record challenge timestamp for rate limiting
        challengeTimestamps[msg.sender].push(block.timestamp);

        // Select 5 random jurors (exclude challenger)
        address[] memory jurors = _selectRandomJurors(challengeId, msg.sender);
        challengeJurors[challengeId] = jurors;

        emit ChallengeCreated(challengeId, tokenId, msg.sender, jurors);
    }

    function vote(uint256 challengeId, bool support) external nonReentrant {
        Challenge storage c = challenges[challengeId];
        require(!c.executed, "CitizenshipJury: challenge executed");
        // Allow voting until finalized; multiple votes not allowed
        require(!voted[challengeId][msg.sender], "CitizenshipJury: already voted");
        address[] memory jurors = challengeJurors[challengeId];
        bool isJuror = false;
        for (uint256 i = 0; i < jurors.length; i++) {
            if (jurors[i] == msg.sender) {
                isJuror = true;
                break;
            }
        }
        require(isJuror, "CitizenshipJury: not a juror");
        voted[challengeId][msg.sender] = true;
        if (support) {
            c.votesFor++;
        } else {
            c.votesAgainst++;
        }
        emit VoteCast(challengeId, msg.sender, support);
    }

    function finalizeChallenge(uint256 challengeId) external nonReentrant {
        Challenge storage c = challenges[challengeId];
        require(!c.executed, "CitizenshipJury: challenge executed");
        uint256 totalVotes = c.votesFor + c.votesAgainst;
        require(totalVotes >= REQUIRED_SIGNATURES, "CitizenshipJury: not enough votes");
        c.executed = true;

        bool revoked = false;
        if (c.votesFor > c.votesAgainst) {
            // Majority to revoke
            citizenshipNFT.juryRevoke(c.tokenId);
            // Burn deposit
            elys.transfer(BURN_ADDRESS, c.deposit);
            revoked = true;
        } else {
            // Refund deposit to challenger
            elys.transfer(c.challenger, c.deposit);
        }

        delete tokenIdToChallengeId[c.tokenId];
        emit ChallengeExecuted(challengeId, revoked);
    }

    function _selectRandomJurors(uint256 challengeId, address challenger) internal returns (address[] memory) {
        uint256 total = citizenshipNFT.totalSupply();
        // First pass: count eligible
        uint256 eligibleCount = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = citizenshipNFT.tokenByIndex(i);
            if (tokenId == 0) continue;
            CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
            // Use _checkEligibility to ensure human non-AI Citizen with H1/H2
            if (_checkEligibility(citizen.wallet) && citizen.wallet != challenger) {
                eligibleCount++;
            }
        }
        require(eligibleCount >= MAX_SIGNERS, "CitizenshipJury: insufficient eligible jurors");

        // Build array of eligible addresses
        address[] memory eligible = new address[](eligibleCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = citizenshipNFT.tokenByIndex(i);
            if (tokenId == 0) continue;
            CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
            if (_checkEligibility(citizen.wallet) && citizen.wallet != challenger) {
                eligible[idx] = citizen.wallet;
                idx++;
            }
        }

        // Randomly select MAX_SIGNERS distinct addresses
        address[] memory selected = new address[](MAX_SIGNERS);
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, challengeId)));
        uint256 poolSize = eligibleCount;
        // Mutable copy of eligible pool
        address[] memory pool = new address[](eligibleCount);
        for (uint256 i = 0; i < eligibleCount; i++) {
            pool[i] = eligible[i];
        }
        for (uint256 i = 0; i < MAX_SIGNERS; i++) {
            seed = uint256(keccak256(abi.encodePacked(seed)));
            uint256 pick = seed % poolSize;
            selected[i] = pool[pick];
            // Swap picked with last and reduce pool size
            pool[pick] = pool[poolSize - 1];
            poolSize--;
        }
        return selected;
    }

    // Optional: Get status of a challenge
    function getChallenge(uint256 challengeId) external view returns (Challenge memory) {
        return challenges[challengeId];
    }

    function getJurors(uint256 challengeId) external view returns (address[] memory) {
        return challengeJurors[challengeId];
    }
}
