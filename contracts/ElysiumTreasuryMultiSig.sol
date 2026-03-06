// SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
   import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
   import "@openzeppelin/contracts/access/AccessControl.sol";
   import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
   import "./CitizenshipNFT.sol";

   contract ElysiumTreasuryMultiSig is ReentrancyGuard, AccessControl {
       bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
       bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

       uint256 public constant REQUIRED_SIGNATURES = 3;
       uint256 private constant MAX_SIGNERS = 5;
       
       // Annual cap: 10% of treasury without 67% supermajority
       uint256 public constant ANNUAL_CAP_BPS = 1000; // 10% in basis points
       uint256 public constant SUPERMAJORITY_BPS = 6700; // 67% approval required to exceed cap
       uint256 public constant YEAR_DURATION = 365 days;
       
       uint256 public annualSpend; // Total spent this fiscal year
       uint256 public fiscalYearStart; // Timestamp of current fiscal year start
       uint256 public signerCount; // Current number of signers

       CitizenshipNFT public immutable citizenshipNFT;

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

       uint256 public nextTransactionId = 0;

       event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value, bytes data);
       event TransactionConfirmed(uint256 indexed txId, address indexed confirmer);
       event TransactionExecuted(uint256 indexed txId, address indexed to, uint256 value);
       event TransactionCancelled(uint256 indexed txId);
       event SignerAdded(address indexed signer);
       event SignerRemoved(address indexed signer);
       event FiscalYearReset(uint256 indexed newYearStart, uint256 previousSpend);
       event AnnualCapExceeded(uint256 indexed txId, uint256 amount, uint256 approvalBps);

       constructor(address[] memory _initialSigners, address _admin, address _citizenshipNft) {
           require(_initialSigners.length <= MAX_SIGNERS, "TreasuryMultiSig: too many signers");
           require(_initialSigners.length >= REQUIRED_SIGNATURES, "TreasuryMultiSig: too few signers");
           citizenshipNFT = CitizenshipNFT(_citizenshipNft);
           _grantRole(DEFAULT_ADMIN_ROLE, _admin);
           fiscalYearStart = block.timestamp;
           annualSpend = 0;
           // signerCount will be set by _addSigner (starts at 0)
           for (uint256 i = 0; i < _initialSigners.length; i++) {
               _addSigner(_initialSigners[i]);
           }
       }

       function _checkEligibility(address signer) internal view returns (bool) {
           uint256 tokenId = citizenshipNFT.citizenTokenId(signer);
           if (tokenId == 0) return false;
           CitizenshipNFT.Citizen memory citizen = citizenshipNFT.getCitizen(tokenId);
           if (citizen.isAI) return false;
           if (citizen.tier < 1) return false; // at least Resident
           // H1 or H2 (phase 1 or 2)
           if (citizen.phase != 1 && citizen.phase != 2) return false;
           return true;
       }
       
       function _updateFiscalYear() internal {
           if (block.timestamp >= fiscalYearStart + YEAR_DURATION) {
               emit FiscalYearReset(block.timestamp, annualSpend);
               fiscalYearStart = block.timestamp;
               annualSpend = 0;
           }
       }
       
       function _checkAnnualCap(uint256 amount, uint256 approvalCount, uint256 totalSigners) internal view returns (bool) {
           uint256 treasuryBalance = address(this).balance;
           uint256 capAmount = (treasuryBalance * ANNUAL_CAP_BPS) / 10000;
           
           // If this transaction would exceed the annual cap
           if (annualSpend + amount > capAmount) {
               // Calculate approval percentage in basis points
               uint256 approvalBps = (approvalCount * 10000) / totalSigners;
               // Require 67% supermajority to exceed cap
               if (approvalBps < SUPERMAJORITY_BPS) {
                   return false;
               }
           }
           return true;
       }
       
       /// @notice Get remaining spend allowed this fiscal year before hitting cap
       function getRemainingCap() external view returns (uint256) {
           uint256 treasuryBalance = address(this).balance;
           uint256 capAmount = (treasuryBalance * ANNUAL_CAP_BPS) / 10000;
           if (annualSpend >= capAmount) return 0;
           return capAmount - annualSpend;
       }
       
       /// @notice Get current fiscal year end timestamp
       function getFiscalYearEnd() external view returns (uint256) {
           return fiscalYearStart + YEAR_DURATION;
       }

       function _addSigner(address signer) internal {
           require(!isSigner[signer], "TreasuryMultiSig: already a signer");
           require(_checkEligibility(signer), "TreasuryMultiSig: ineligible signer");
           _grantRole(SIGNER_ROLE, signer);
           isSigner[signer] = true;
           signerCount++;
           emit SignerAdded(signer);
       }

       function _removeSigner(address signer) internal {
           require(isSigner[signer], "TreasuryMultiSig: not a signer");
           _revokeRole(SIGNER_ROLE, signer);
           isSigner[signer] = false;
           signerCount--;
       }

       function submitTransaction(address to, uint256 value, bytes calldata data) external onlyRole(SIGNER_ROLE) {
           transactions.push(Transaction({
               value: value,
               to: to,
               data: data,
               executed: false,
               approvals: 1
           }));
           uint256 txId = nextTransactionId++;
           isConfirmed[txId][msg.sender] = true;
           emit TransactionSubmitted(txId, to, value, data);
           emit TransactionConfirmed(txId, msg.sender);
       }

       function confirmTransaction(uint256 txId) external onlyRole(SIGNER_ROLE) {
           Transaction storage txn = transactions[txId];
           require(txn.value > 0 || txn.to != address(0) || txn.data.length > 0, "Treasury: invalid transaction");
           require(!txn.executed, "Treasury: already executed");
           require(!isConfirmed[txId][msg.sender], "Treasury: already confirmed");
           isConfirmed[txId][msg.sender] = true;
           txn.approvals += 1;
           emit TransactionConfirmed(txId, msg.sender);
       }

       function executeTransaction(uint256 txId) external nonReentrant onlyRole(SIGNER_ROLE) {
           Transaction storage txn = transactions[txId];
           require(!txn.executed, "Treasury: already executed");
           require(txn.approvals >= REQUIRED_SIGNATURES, "Treasury: not enough confirmations");
           
           // Update fiscal year if needed
           _updateFiscalYear();
           
           // Check if this exceeds cap and emit event if supermajority approves
           uint256 treasuryBalance = address(this).balance;
           uint256 capAmount = (treasuryBalance * ANNUAL_CAP_BPS) / 10000;
           if (annualSpend + txn.value > capAmount) {
               uint256 approvalBps = (txn.approvals * 10000) / signerCount;
               emit AnnualCapExceeded(txId, txn.value, approvalBps);
           }
           
           // Check annual cap (requires supermajority if exceeded)
           require(_checkAnnualCap(txn.value, txn.approvals, signerCount), "Treasury: annual cap exceeded without supermajority");
           
           (bool success, ) = txn.to.call{value: txn.value}(txn.data);
           require(success, "Treasury: execution failed");
           txn.executed = true;
           annualSpend += txn.value;
           emit TransactionExecuted(txId, txn.to, txn.value);
       }

       function cancelTransaction(uint256 txId) external onlyRole(ADMIN_ROLE) {
           Transaction storage txn = transactions[txId];
           require(!txn.executed, "Treasury: already executed");
           delete transactions[txId];
           emit TransactionCancelled(txId);
       }

       function addSigner(address signer) external onlyRole(ADMIN_ROLE) {
           _addSigner(signer);
       }

       function removeSigner(address signer) external onlyRole(ADMIN_ROLE) {
           _removeSigner(signer);
       }

       receive() external payable {}
       fallback() external payable {}
   }