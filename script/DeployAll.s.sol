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

        // 6. Define multisig signers (customize before deploying to testnet/mainnet)
        // IMPORTANT: Replace these with actual eligible addresses before production deployment.
        address[] memory upgradeSigners = new address[](5);
        upgradeSigners[0] = 0xE6b935031c7BaD3A2e4Bc0B15AF4c57963719cBE;
        upgradeSigners[1] = 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE;
        upgradeSigners[2] = 0xE3Cc7740A4a9Bfe5cd78F7D9532d23B51f9a5b74;
        upgradeSigners[3] = 0x3D45B09ED77A4525822a8dC379d26Bd799957c43;
        upgradeSigners[4] = 0x698171228D3AB667FD3B5B18b08Ebf8CbF9CF3BF;

        address[] memory pauseSigners = new address[](3);
        pauseSigners[0] = 0xE6b935031c7BaD3A2e4Bc0B15AF4c57963719cBE;
        pauseSigners[1] = 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE;
        pauseSigners[2] = 0xE3Cc7740A4a9Bfe5cd78F7D9532d23B51f9a5b74;

        address[] memory treasurySigners = new address[](5);
        treasurySigners[0] = 0xE6b935031c7BaD3A2e4Bc0B15AF4c57963719cBE;
        treasurySigners[1] = 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE;
        treasurySigners[2] = 0xE3Cc7740A4a9Bfe5cd78F7D9532d23B51f9a5b74;
        treasurySigners[3] = 0x3D45B09ED77A4525822a8dC379d26Bd799957c43;
        treasurySigners[4] = 0x698171228D3AB667FD3B5B18b08Ebf8CbF9CF3BF;

        address[] memory jurySigners = new address[](5);
        jurySigners[0] = 0xE6b935031c7BaD3A2e4Bc0B15AF4c57963719cBE;
        jurySigners[1] = 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE;
        jurySigners[2] = 0xE3Cc7740A4a9Bfe5cd78F7D9532d23B51f9a5b74;
        jurySigners[3] = 0x3D45B09ED77A4525822a8dC379d26Bd799957c43;
        jurySigners[4] = 0x698171228D3AB667FD3B5B18b08Ebf8CbF9CF3BF;

        // 7. Mint Founder-tier (3), H1 (phase=1) NFTs for all signers
        for (uint256 i = 0; i < upgradeSigners.length; i++) {
            citizenshipNFT.mintHuman(upgradeSigners[i], 3, 1, "");
        }
        for (uint256 i = 0; i < pauseSigners.length; i++) {
            citizenshipNFT.mintHuman(pauseSigners[i], 3, 1, "");
        }
        for (uint256 i = 0; i < treasurySigners.length; i++) {
            citizenshipNFT.mintHuman(treasurySigners[i], 3, 1, "");
        }
        for (uint256 i = 0; i < jurySigners.length; i++) {
            citizenshipNFT.mintHuman(jurySigners[i], 3, 1, "");
        }

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
