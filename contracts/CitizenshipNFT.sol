// SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
   import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
   import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
   import "@openzeppelin/contracts/access/AccessControl.sol";
   import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

   interface IERC5484 is IERC165 {}
   interface IOperatorRegistry {
       function verifyAttestation(address aiWallet, address operator) external view returns (bool valid, uint256 count);
   }

   contract CitizenshipNFT is ERC721, ERC721Enumerable, IERC5484, AccessControl {
       bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
       bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
       bytes32 public constant JURY_ROLE = keccak256("JURY_ROLE");

       struct Citizen {
           uint256 citizenId;
           address wallet;
           uint256 tier;
           uint256 phase;
           uint256 createdAt;
           bool isAI;
           string metadataURI;
       }

       mapping(uint256 => Citizen) public citizens;
       mapping(address => uint256) public walletToTokenId;
       address public operatorRegistry;
       uint256 public nextCitizenId = 1;
       mapping(address => bool) public hasCitizenship;
       uint256 public constant MAX_AI_PER_OPERATOR = 10;

       event CitizenshipAwarded(address indexed to, uint256 tokenId, uint256 tier, bool isAI);
       event CitizenshipRevoked(address indexed from, uint256 tokenId);

       constructor(address _operatorRegistry) ERC721("Elysium Citizenship", "ELYS-C") {
           _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
           _grantRole(MINTER_ROLE, msg.sender);
           _grantRole(VERIFIER_ROLE, msg.sender); // Deployer can verify human phases
           _grantRole(JURY_ROLE, msg.sender); // Deployer can manage jury role initially
           operatorRegistry = _operatorRegistry;
       }

       function mintHuman(address wallet, uint256 tier, uint256 phase, string memory metadataURI)
           external onlyRole(MINTER_ROLE)
           returns (uint256 tokenId)
       {
           require(!hasCitizenship[wallet], "Citizenship: already a citizen");
           tokenId = nextCitizenId++;
           _mint(wallet, tokenId);
           citizens[tokenId] = Citizen({
               citizenId: tokenId,
               wallet: wallet,
               tier: tier,
               phase: phase,
               createdAt: block.timestamp,
               isAI: false,
               metadataURI: metadataURI
           });
           hasCitizenship[wallet] = true;
           walletToTokenId[wallet] = tokenId;
           emit CitizenshipAwarded(wallet, tokenId, tier, false);
       }

       function mintAI(address wallet, address operator, string memory metadataURI)
           external onlyRole(MINTER_ROLE)
           returns (uint256 tokenId)
       {
           require(!hasCitizenship[wallet], "Citizenship: already a citizen");
           require(operator != address(0), "Citizenship: invalid operator");
           (bool valid, uint256 count) = IOperatorRegistry(operatorRegistry).verifyAttestation(wallet, operator);
           require(valid, "Citizenship: operator attestation invalid");
           require(count < MAX_AI_PER_OPERATOR, "Citizenship: operator AI limit exceeded");
           tokenId = nextCitizenId++;
           _mint(wallet, tokenId);
           citizens[tokenId] = Citizen({
               citizenId: tokenId,
               wallet: wallet,
               tier: 0,
               phase: 1, // AI Phase 1: Advisory (no voting)
               createdAt: block.timestamp,
               isAI: true,
               metadataURI: metadataURI
           });
           hasCitizenship[wallet] = true;
           walletToTokenId[wallet] = tokenId;
           emit CitizenshipAwarded(wallet, tokenId, 0, true);
       }

       function revoke(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
           address owner = ownerOf(tokenId);
           hasCitizenship[owner] = false;
           delete walletToTokenId[owner];
           delete citizens[tokenId];
           _burn(tokenId);
           emit CitizenshipRevoked(owner, tokenId);
       }

       function juryRevoke(uint256 tokenId) external onlyRole(JURY_ROLE) {
           address owner = ownerOf(tokenId);
           hasCitizenship[owner] = false;
           delete walletToTokenId[owner];
           delete citizens[tokenId];
           _burn(tokenId);
           emit CitizenshipRevoked(owner, tokenId);
       }

       function updateTier(uint256 tokenId, uint256 newTier) external onlyRole(DEFAULT_ADMIN_ROLE) {
           require(_ownerOf(tokenId) != address(0), "Citizenship: token does not exist");
           citizens[tokenId].tier = newTier;
       }

       function updatePhase(uint256 tokenId, uint256 newPhase) external onlyRole(VERIFIER_ROLE) {
           require(_ownerOf(tokenId) != address(0), "Citizenship: token does not exist");
           require(newPhase >= 1 && newPhase <= 3, "Citizenship: invalid phase");
           citizens[tokenId].phase = newPhase;
       }

       function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
           require(_ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
           return citizens[tokenId].metadataURI;
       }

       function getCitizen(uint256 tokenId) external view returns (Citizen memory) {
           require(_ownerOf(tokenId) != address(0), "Citizenship: token does not exist");
           return citizens[tokenId];
       }

       function getCitizenByAddress(address wallet) external view returns (Citizen memory) {
           uint256 tokenId = walletToTokenId[wallet];
           require(tokenId > 0 && _ownerOf(tokenId) != address(0), "Citizenship: not a citizen");
           return citizens[tokenId];
       }

       function citizenTokenId(address wallet) public view returns (uint256) {
           return walletToTokenId[wallet];
       }

       function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl, IERC165) returns (bool) {
           return interfaceId == type(IERC165).interfaceId || 
                  interfaceId == type(IERC5484).interfaceId || 
                  interfaceId == type(ERC721Enumerable).interfaceId ||
                  super.supportsInterface(interfaceId);
       }

       // Soulbound: mint and burn allowed; other transfers blocked
       function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
           address from = _ownerOf(tokenId);
           require(from == address(0) || to == address(0), "ERC5484: cannot transfer soulbound token");
           return super._update(to, tokenId, auth);
       }
       
       // Required for ERC721Enumerable compatibility
       function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
           super._increaseBalance(account, value);
       }
   }