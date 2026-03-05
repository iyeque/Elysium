// SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
   import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
   import "@openzeppelin/contracts/access/AccessControl.sol";
   import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

   contract ElysiumTreasury is ReentrancyGuard, AccessControl {
       bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
       bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

       uint256 public constant REQUIRED_SIGNATURES = 3;
       uint256 private constant MAX_SIGNERS = 5;

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

       event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value, bytes data);
       event TransactionConfirmed(uint256 indexed txId, address indexed confirmer);
       event TransactionExecuted(uint256 indexed txId, address indexed to, uint256 value);
       event TransactionCancelled(uint256 indexed txId);
       event SignerAdded(address indexed signer);
       event SignerRemoved(address indexed signer);

       constructor(address[] memory _initialSigners, address _admin) {
           require(_initialSigners.length <= MAX_SIGNERS, "Treasury: too many signers");
           require(_initialSigners.length >= REQUIRED_SIGNATURES, "Treasury: too few signers");
           _grantRole(DEFAULT_ADMIN_ROLE, _admin);
           for (uint256 i = 0; i < _initialSigners.length; i++) {
               _addSigner(_initialSigners[i]);
           }
       }

       function _addSigner(address signer) internal {
           require(!isSigner[signer], "Treasury: already a signer");
           _grantRole(SIGNER_ROLE, signer);
           isSigner[signer] = true;
           emit SignerAdded(signer);
       }

       function _removeSigner(address signer) internal {
           require(isSigner[signer], "Treasury: not a signer");
           _revokeRole(SIGNER_ROLE, signer);
           isSigner[signer] = false;
       }

       function submitTransaction(address to, uint256 value, bytes calldata data) external onlyRole(SIGNER_ROLE) {
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
           (bool success, ) = txn.to.call{value: txn.value}(txn.data);
           require(success, "Treasury: execution failed");
           txn.executed = true;
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