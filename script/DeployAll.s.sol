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
    uint256 internal constant MIN_DELAY = 2 days;

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

    function _mintIfNew(address[] memory addrs) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            address a = addrs[i];
            if (!minted[a]) {
                citizenshipNFT.mintHuman(a, 3, 1, "");
                minted[a] = true;
            }
        }
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. Deploy ELYS token
        elys = new ELYS(address(0));
        console.log("ELYS deployed at:", address(elys));

        // 2. Deploy Timelock (2 days delay)
        timelock = new ElysiumTimelock(2 days, new address[](0), new address[](0), msg.sender);
        console.log("Timelock deployed at:", address(timelock));

        // 3. Deploy OperatorRegistry
        operatorRegistry = new OperatorRegistry(address(0));
        console.log("OperatorRegistry deployed at:", address(operatorRegistry));

        // 4. Deploy CitizenshipNFT
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        console.log("CitizenshipNFT deployed at:", address(citizenshipNFT));

        // 5. Update OperatorRegistry
        operatorRegistry.setCitizenshipNft(address(citizenshipNFT));

        // 6. Use the first 5 anvil accounts as signers for all multisigs (distinct subsets)
        address[] memory baseSigners = new address[](5);
        baseSigners[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        baseSigners[1] = 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
        baseSigners[2] = 0x6b3595068778DDB901d426cF4cf47D7dD4BF8c6D;
        baseSigners[3] = 0x3c84B3D7E3419D0891bAd1A5e1f0AC92c9A68Cb1;
        baseSigners[4] = 0x0087e5b90d452c89998a78b1b155445bd1A8e108;

        // Upgrade: all 5
        address[] memory upgradeSigners = baseSigners;

        // Pause: subset of first 3 (to satisfy max 3 signers)
        address[] memory pauseSigners = new address[](3);
        pauseSigners[0] = baseSigners[0];
        pauseSigners[1] = baseSigners[1];
        pauseSigners[2] = baseSigners[2];

        // Treasury: all 5
        address[] memory treasurySigners = baseSigners;

        // Jury: all 5
        address[] memory jurySigners = baseSigners;

        // 7. Mint Founder-tier (3), H1 (phase=1) NFTs for all signers (avoid duplicates)
        _mintIfNew(upgradeSigners);
        _mintIfNew(pauseSigners);
        _mintIfNew(treasurySigners);
        _mintIfNew(jurySigners);

        // 8. Deploy Staking
        staking = new Staking(address(elys), address(citizenshipNFT));
        console.log("Staking deployed at:", address(staking));

        // 9. Deploy multisig authorities
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
        timelock.grantRole(keccak256("PROPOSER_ROLE"), address(governor));
        timelock.grantRole(keccak256("EXECUTOR_ROLE"), address(governor));

        treasury.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        pauseMultiSig.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        upgradeMultiSig.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        citizenshipJury.grantRole(keccak256("ADMIN_ROLE"), address(governor));
        citizenshipNFT.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), address(governor));

        staking.grantRole(keccak256("PAUSER_ROLE"), address(pauseMultiSig));
        citizenshipNFT.grantRole(keccak256("MINTER_ROLE"), address(staking));
        citizenshipNFT.grantRole(keccak256("JURY_ROLE"), address(citizenshipJury));

        elys.setRewardsPool(address(staking));
        console.log("ELYS rewards pool set to Staking");

        staking.grantRole(keccak256("REWARDER_ROLE"), address(treasury));
        console.log("Granted Staking REWARDER_ROLE to Treasury");

        vm.stopBroadcast();

        console.log("Deployment complete!");
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
