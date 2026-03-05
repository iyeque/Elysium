// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { ELYS } from "../contracts/ELYS.sol";
import { ElysiumTimelock } from "../contracts/ElysiumTimelock.sol";
import { ElysiumGovernor } from "../contracts/ElysiumGovernor.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { ElysiumTreasury } from "../contracts/ElysiumTreasury.sol";
import { Staking } from "../contracts/Staking.sol";

contract DeployAll is Script {
    uint256 internal constant MIN_DELAY = 2 days;
    address[] internal proposers;
    address[] internal executors;

    ELYS elys;
    ElysiumTimelock timelock;
    ElysiumGovernor governor;
    OperatorRegistry operatorRegistry;
    CitizenshipNFT citizenshipNFT;
    ElysiumTreasury treasury;
    Staking staking;

    // Initial signers for treasury (will be replaced by governance later)
    address[] public initialSigners = [
        address(0xE6b935031c7bAd3A2E4bC0b15Af4c57963719Cbe),
        address(0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE),
        address(0xE3cC7740a4a9bFe5cD78F7D9532d23B51F9A5b74),
        address(0x3d45B09eD77a4525822A8Dc379D26bD799957c43),
        address(0x698171228d3aB667fd3b5b18b08eBf8cBF9cF3bF)
    ];

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. Deploy ELYS token
        elys = new ELYS();
        console.log("ELYS deployed at:", address(elys));

        // 2. Deploy Timelock (with empty proposers/executors, will grant later)
        timelock = new ElysiumTimelock(MIN_DELAY, new address[](0), new address[](0));
        console.log("Timelock deployed at:", address(timelock));

        // 3. Deploy OperatorRegistry
        operatorRegistry = new OperatorRegistry(address(0)); // placeholder
        console.log("OperatorRegistry deployed at:", address(operatorRegistry));

        // 4. Deploy CitizenshipNFT
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        console.log("CitizenshipNFT deployed at:", address(citizenshipNFT));

        // 5. Update OperatorRegistry with CitizenshipNFT address
        operatorRegistry.setCitizenshipNFT(address(citizenshipNFT));

        // 6. Deploy Staking
        staking = new Staking(address(elys), address(citizenshipNFT));
        console.log("Staking deployed at:", address(staking));

        // 7. Deploy Treasury
        treasury = new ElysiumTreasury(initialSigners, msg.sender);
        console.log("Treasury deployed at:", address(treasury));

        // 8. Deploy Governor
        governor = new ElysiumGovernor(
            address(elys),
            address(timelock),
            1 days,   // votingDelay
            7 days,   // votingPeriod
            100 * 10**18 // proposalThreshold: 100 ELYS
        );
        console.log("Governor deployed at:", address(governor));

        // 9. Set up roles and relationships
        // Grant governor both proposer and executor roles on timelock
        timelock.grantRole(keccak256("PROPOSER_ROLE"), address(governor));
        timelock.grantRole(keccak256("EXECUTOR_ROLE"), address(governor));

        // Grant governor admin on treasury (to change signers)
        treasury.grantRole(keccak256("ADMIN_ROLE"), address(governor));

        // For completeness, we could also make operatorRegistry manageable by governor
        // operatorRegistry.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), address(governor));

        // 10. Mint test tokens to treasury (for liquidity/awards later)
        // elys.transfer(address(treasury), 100_000 * 10**18);

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("Governor:", address(governor));
        console.log("Timelock:", address(timelock));
        console.log("Token:", address(elys));
        console.log("CitizenshipNFT:", address(citizenshipNFT));
        console.log("Staking:", address(staking));
        console.log("Treasury:", address(treasury));
        console.log("OperatorRegistry:", address(operatorRegistry));
    }
}
