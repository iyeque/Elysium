// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { ELYS } from "../contracts/ELYS.sol";
import { ElysiumTimelock } from "../contracts/ElysiumTimelock.sol";
import { ElysiumGovernor } from "../contracts/ElysiumGovernor.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { ElysiumTreasuryMultiSig } from "../contracts/ElysiumTreasuryMultiSig.sol";
import { Staking } from "../contracts/Staking.sol";
import { ElysiumPauseMultiSig } from "../contracts/ElysiumPauseMultiSig.sol";
import { ElysiumUpgradeMultiSig } from "../contracts/ElysiumUpgradeMultiSig.sol";
import { CitizenshipJury } from "../contracts/CitizenshipJury.sol";

contract DeployAll is Script {
    uint256 internal constant DEFAULT_TIMELOCK_DELAY = 2 days;

    ELYS elys;
    ElysiumTimelock timelock;
    ElysiumGovernor governor;
    OperatorRegistry operatorRegistry;
    CitizenshipNFT citizenshipNFT;
    ElysiumTreasuryMultiSig treasury;
    Staking staking;
    ElysiumPauseMultiSig pauseMultiSig;
    ElysiumUpgradeMultiSig upgradeMultiSig;
    CitizenshipJury citizenshipJury;

    mapping(address => bool) private minted;
    uint256 private mintedCounter;

    /// @notice Mint Founder-tier H1 NFTs for given addresses, avoiding duplicates
    function _mintIfNew(address[] memory addrs) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            address a = addrs[i];
            if (!minted[a]) {
                citizenshipNFT.mintHuman(a, 3, 1, "");
                minted[a] = true;
                mintedCounter++;
            }
        }
    }

    /// @notice Parse comma-separated hex addresses into address array
    function _parseAddresses(string memory csv) internal pure returns (address[] memory) {
        bytes memory b = bytes(csv);
        if (b.length == 0) return new address[](0);
        // Count addresses by counting commas
        uint256 count = 1;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ',') count++;
        }
        address[] memory result = new address[](count);
        uint256 start = 0;
        uint256 idx = 0;
        // Iterate to find each comma or end of string
        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ',') {
                uint256 end = i;
                result[idx] = _parseAddrFromBytes(b, start, end);
                start = i + 1;
                idx++;
            }
        }
        return result;
    }

    /// @notice Parse a single address from a bytes slice [start, end)
    function _parseAddrFromBytes(bytes memory b, uint256 start, uint256 end) internal pure returns (address) {
        uint256 len = end - start;
        require(len == 42 && b[start] == '0' && b[start+1] == 'x', "invalid address format");
        uint160 addrUint = 0;
        for (uint256 i = 0; i < 20; i++) {
            uint8 hi = _hex(uint8(b[start + 2 + i*2]));
            uint8 lo = _hex(uint8(b[start + 3 + i*2]));
            uint8 byteVal = (hi << 4) + lo;
            addrUint = (addrUint << 8) | byteVal;
        }
        return address(addrUint);
    }

    function _hex(uint8 c) internal pure returns (uint8) {
        if (c >= 48 && c <= 57) return c - 48;
        if (c >= 97 && c <= 102) return c - 87;
        if (c >= 65 && c <= 70) return c - 55;
        revert("invalid hex");
    }

    /// @notice Read signer addresses from environment variable or use default set
    function _getSigners(string memory envVar, address[] memory defaultSigners) internal returns (address[] memory) {
        string memory csv = vm.envString(envVar);
        if (bytes(csv).length > 0) {
            address[] memory parsed = _parseAddresses(csv);
            require(parsed.length > 0, "empty signer list after parse");
            return parsed;
        }
        return defaultSigners;
    }

    /// @notice Get timelock delay from env var (days) or use default
    function _getTimelockDelay() internal returns (uint256) {
        string memory s = vm.envString("TIMELOCK_DELAY_DAYS");
        if (bytes(s).length > 0) {
            uint256 delayDays = _parseUint(s);
            require(delayDays >= 1, "timelock delay must be at least 1 day");
            return delayDays * 24 hours; // Convert days to seconds
        }
        return DEFAULT_TIMELOCK_DELAY;
    }

    /// @notice Parse decimal string into uint256
    function _parseUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            require(c >= 48 && c <= 57, "invalid digit in number");
            result = result * 10 + (c - 48);
        }
        return result;
    }

    /// @notice Default signers for local anvil (5 accounts)
    function _defaultUpgradeSigners() internal pure returns (address[] memory) {
        address[] memory signers = new address[](5);
        signers[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        signers[1] = 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
        signers[2] = 0x6b3595068778DDB901d426cF4cf47D7dD4BF8c6D;
        signers[3] = 0x3c84B3D7E3419D0891bAd1A5e1f0AC92c9A68Cb1;
        signers[4] = 0x0087e5b90d452c89998a78b1b155445bd1A8e108;
        return signers;
    }

    /// @notice Default pause signers (first 3 of upgrade signers)
    function _defaultPauseSigners() internal pure returns (address[] memory) {
        address[] memory signers = new address[](3);
        signers[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        signers[1] = 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
        signers[2] = 0x6b3595068778DDB901d426cF4cf47D7dD4BF8c6D;
        return signers;
    }

    /// @notice Default treasury signers (same as upgrade)
    function _defaultTreasurySigners() internal pure returns (address[] memory) {
        return _defaultUpgradeSigners();
    }

    /// @notice Default jury signers (same as upgrade)
    function _defaultJurySigners() internal pure returns (address[] memory) {
        return _defaultUpgradeSigners();
    }

    /// @notice Validate signer array length and ensure no zero addresses
    function _validateSigners(address[] memory signers, uint256 max, uint256 min, string memory name) internal pure {
        require(signers.length <= max, string(abi.encodePacked(name, ": too many signers")));
        require(signers.length >= min, string(abi.encodePacked(name, ": too few signers")));
        for (uint256 i = 0; i < signers.length; i++) {
            require(signers[i] != address(0), string(abi.encodePacked(name, ": contains zero address")));
        }
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. Deploy ELYS token
        // Initial rewardsPool is address(0); it will be set after Staking is deployed
        elys = new ELYS(address(0));
        console.log("ELYS deployed at:", address(elys));

        // 2. Deploy Timelock with configurable delay (default 2 days)
        uint256 timelockDelay = _getTimelockDelay();
        timelock = new ElysiumTimelock(timelockDelay, new address[](0), new address[](0), msg.sender);
        console.log("Timelock deployed at:", address(timelock), "delay:", timelockDelay);

        // 3. Deploy OperatorRegistry with placeholder CitizenshipNFT (will set later)
        operatorRegistry = new OperatorRegistry(address(0));
        console.log("OperatorRegistry deployed at:", address(operatorRegistry));

        // 4. Deploy CitizenshipNFT linked to OperatorRegistry
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        console.log("CitizenshipNFT deployed at:", address(citizenshipNFT));

        // 5. Update OperatorRegistry with the actual CitizenshipNFT address
        operatorRegistry.setCitizenshipNft(address(citizenshipNFT));
        console.log("OperatorRegistry CitizenshipNFT set");

        // 6. Determine signer addresses for each multisig
        // Use environment variables if provided, otherwise default to anvil accounts
        address[] memory upgradeSigners = _getSigners("UPGRADE_SIGNERS", _defaultUpgradeSigners());
        address[] memory pauseSigners = _getSigners("PAUSE_SIGNERS", _defaultPauseSigners());
        address[] memory treasurySigners = _getSigners("TREASURY_SIGNERS", _defaultTreasurySigners());
        address[] memory jurySigners = _getSigners("JURY_SIGNERS", _defaultJurySigners());

        // Validate signer counts: max and min per multisig
        _validateSigners(upgradeSigners, 5, 3, "Upgrade");
        _validateSigners(pauseSigners, 3, 2, "Pause");
        _validateSigners(treasurySigners, 5, 3, "Treasury");
        _validateSigners(jurySigners, 5, 3, "Jury");

        // 7. Mint Founder-tier (tier=3), H1 (phase=1) NFTs for all distinct signers
        mintedCounter = 0;
        _mintIfNew(upgradeSigners);
        _mintIfNew(pauseSigners);
        _mintIfNew(treasurySigners);
        _mintIfNew(jurySigners);
        console.log("Minted Founder-tier H1 NFTs for", mintedCounter, "unique signers");

        // 8. Deploy Staking, linked to ELYS and CitizenshipNFT
        staking = new Staking(address(elys), address(citizenshipNFT));
        console.log("Staking deployed at:", address(staking));

        // 9. Deploy multisig authorities with signers and admin = deployer
        treasury = new ElysiumTreasuryMultiSig(treasurySigners, msg.sender, address(citizenshipNFT));
        console.log("Treasury Multi-Sig deployed at:", address(treasury));

        pauseMultiSig = new ElysiumPauseMultiSig(pauseSigners, msg.sender, address(citizenshipNFT));
        console.log("Pause Multi-Sig deployed at:", address(pauseMultiSig));

        upgradeMultiSig = new ElysiumUpgradeMultiSig(upgradeSigners, msg.sender, address(citizenshipNFT));
        console.log("Upgrade Multi-Sig deployed at:", address(upgradeMultiSig));

        citizenshipJury = new CitizenshipJury(jurySigners, msg.sender, address(citizenshipNFT), address(elys));
        console.log("Citizenship Jury deployed at:", address(citizenshipJury));

        // 10. Deploy Governor
        governor = new ElysiumGovernor(citizenshipNFT, timelock, "Elysium Governor", msg.sender);
        console.log("Governor deployed at:", address(governor));

        // 11. Configure roles and permissions

        // Timelock: Governor can propose and execute
        timelock.grantRole(keccak256("PROPOSER_ROLE"), address(governor));
        timelock.grantRole(keccak256("EXECUTOR_ROLE"), address(governor));

        // Multisigs: Governor becomes admin to manage signers
        treasury.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        pauseMultiSig.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        upgradeMultiSig.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        citizenshipJury.grantRole(keccak256("ADMIN_ROLE"), address(governor));

        // CitizenshipNFT: Governor gets DEFAULT_ADMIN to manage roles (MINTER, VERIFIER, JURY, etc.)
        citizenshipNFT.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), address(governor));

        // Staking: PauseMultiSig can pause; Treasury can add rewards
        staking.grantRole(keccak256("PAUSER_ROLE"), address(pauseMultiSig));
        staking.grantRole(keccak256("REWARDER_ROLE"), address(treasury));

        // Staking can mint citizenship when stake threshold reached
        citizenshipNFT.grantRole(keccak256("MINTER_ROLE"), address(staking));

        // CitizenshipJury needs JURY_ROLE for challenge operations
        citizenshipNFT.grantRole(keccak256("JURY_ROLE"), address(citizenshipJury));

        // 12. Finalize token configuration
        // Set ELYS rewards pool to Staking contract so fees are distributed to stakers
        elys.setRewardsPool(address(staking));
        console.log("ELYS rewards pool set to Staking");

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("=== Contract Addresses ===");
        console.log("Governor:", address(governor));
        console.log("Timelock:", address(timelock));
        console.log("Token:", address(elys));
        console.log("CitizenshipNFT:", address(citizenshipNFT));
        console.log("Staking:", address(staking));
        console.log("Treasury Multi-Sig:", address(treasury));
        console.log("Pause Multi-Sig:", address(pauseMultiSig));
        console.log("Upgrade Multi-Sig:", address(upgradeMultiSig));
        console.log("Citizenship Jury:", address(citizenshipJury));
        console.log("OperatorRegistry:", address(operatorRegistry));
    }
}
