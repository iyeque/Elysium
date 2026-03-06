// SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/access/AccessControl.sol";

   contract OperatorRegistry is AccessControl {
       bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
       bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");
       uint256 public constant MAX_AI_PER_OPERATOR = 10;

       struct Attestation {
           address operator;
           uint256 timestamp;
           uint256 nonce;
       }

       mapping(address => Attestation) public aiAttestations;
       mapping(address => uint256) public operatorAICount;
       mapping(address => mapping(address => uint256)) public operatorNonces;
       address public citizenshipNFT;

       event AIAttested(address indexed aiWallet, address indexed operator, uint256 nonce);
       event AIRevoked(address indexed aiWallet, address indexed operator);
       event CitizenshipNFTUpdated(address _citizenshipNft);

       constructor(address _citizenshipNft) {
           _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
           _grantRole(OPERATOR_ROLE, msg.sender);
           _grantRole(ATTESTER_ROLE, msg.sender);
           citizenshipNFT = _citizenshipNft;
       }

       function setCitizenshipNft(address _citizenshipNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
           citizenshipNFT = _citizenshipNft;
           emit CitizenshipNFTUpdated(_citizenshipNft);
       }

       function attestAi(address aiWallet) external onlyRole(OPERATOR_ROLE) {
           require(aiWallet != msg.sender, "Operator: self-attestation not allowed");
           require(aiWallet != address(0), "Operator: zero address");
           address existingOperator = aiAttestations[aiWallet].operator;
           require(existingOperator == address(0) || existingOperator == msg.sender, "Operator: wallet already claimed");
           if (existingOperator == address(0)) {
               require(operatorAICount[msg.sender] < MAX_AI_PER_OPERATOR, "Operator: AI limit exceeded");
               operatorAICount[msg.sender] += 1;
           }
           aiAttestations[aiWallet] = Attestation({
               operator: msg.sender,
               timestamp: block.timestamp,
               nonce: operatorNonces[msg.sender][aiWallet] + 1
           });
           emit AIAttested(aiWallet, msg.sender, operatorNonces[msg.sender][aiWallet] + 1);
       }

       function revokeAi(address aiWallet) external onlyRole(OPERATOR_ROLE) {
           Attestation storage att = aiAttestations[aiWallet];
           require(att.operator == msg.sender, "Operator: not your attestation");
           operatorAICount[msg.sender] -= 1;
           delete aiAttestations[aiWallet];
           emit AIRevoked(aiWallet, msg.sender);
       }

       function verifyAttestation(address aiWallet, address operator) external view returns (bool valid, uint256 count) {
           Attestation memory att = aiAttestations[aiWallet];
           valid = att.operator == operator;
           if (valid) count = operatorAICount[operator];
           else count = 0;
       }

       function getOperatorCount(address operator) external view returns (uint256) {
           return operatorAICount[operator];
       }

       function getAttestation(address aiWallet) external view returns (Attestation memory) {
           return aiAttestations[aiWallet];
       }
   }