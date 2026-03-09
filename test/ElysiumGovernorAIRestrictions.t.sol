// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ElysiumGovernor } from "../contracts/ElysiumGovernor.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

// Mock operator registry that always approves attestations
contract MockOperatorRegistry {
    function verifyAttestation(address, address) external pure returns (bool valid, uint256 count) {
        return (true, 0);
    }
}

contract ElysiumGovernorAIRestrictionsTest is Test {
    ElysiumGovernor governor;
    CitizenshipNFT citizenshipNFT;
    MockOperatorRegistry mockOperatorRegistry;
    TimelockController timelock;

    address admin = address(this);
    address aiWallet = address(0x10);
    address humanWallet = address(0x11);
    uint256 aiTokenId;

    function setUp() public {
        // Deploy mock operator registry
        mockOperatorRegistry = new MockOperatorRegistry();

        // Deploy CitizenshipNFT with mock operator registry
        citizenshipNFT = new CitizenshipNFT(address(mockOperatorRegistry));
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), admin);

        // Deploy TimelockController (2 days delay, empty proposers/executors, admin)
        timelock = new TimelockController(2 days, new address[](0), new address[](0), admin);

        // Deploy Governor (founder address for veto window)
        governor = new ElysiumGovernor(citizenshipNFT, timelock, "Elysium", admin);

        // Grant Timelock roles to Governor
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));

        // Mint AI citizen (default phase 1)
        vm.prank(admin);
        aiTokenId = citizenshipNFT.mintAi(aiWallet, address(mockOperatorRegistry), "");
        citizenshipNFT.updateTier(aiTokenId, 1); // Set tier to Resident

        // Mint human citizen
        vm.prank(admin);
        citizenshipNFT.mintHuman(humanWallet, 1, 1, "");
    }

    function test_AI_Phase1_VoteWeight() public {
        uint256 votes = governor.getVotes(aiWallet, block.number);
        assertEq(votes, 0);
    }

    function test_AI_Phase2_VoteWeight() public {
        // Wait 30 days before phase transition
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 2);
        uint256 votes = governor.getVotes(aiWallet, block.number);
        assertEq(votes, (1 ether * 5000) / 10000); // 0.5x
    }

    function test_AI_Phase3_VoteWeight() public {
        // First transition to phase 2 after 30 days
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 2);
        // Then wait another 30 days to transition to phase 3
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 3);
        uint256 votes = governor.getVotes(aiWallet, block.number);
        assertEq(votes, 1 ether);
    }

    function test_Human_VoteWeight() public {
        uint256 votes = governor.getVotes(humanWallet, block.number);
        assertEq(votes, 1 ether);
    }

    function test_AI_Phase2_Propose_ParameterChange_Allowed() public {
        // Wait 30 days before phase transition
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 2);

        // Dummy proposal with minimal non-empty arrays
        address[] memory targets = new address[](1);
        targets[0] = address(0);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";

        vm.prank(aiWallet);
        governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test param",
            targets,
            values,
            calldatas
        );
    }

    function test_AI_Phase1_Propose_ParameterChange_Allowed() public {
        address[] memory targets = new address[](1);
        targets[0] = address(0);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";

        vm.prank(aiWallet);
        governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Param",
            targets,
            values,
            calldatas
        );
    }

    function test_AI_Phase2_Propose_TreasurySpendSmall_Reverts() public {
        // Wait 30 days before phase transition
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 2);

        address[] memory targets = new address[](1);
        targets[0] = address(0x99);
        uint256[] memory values = new uint256[](1);
        values[0] = 1000 * 1e18;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";

        vm.prank(aiWallet);
        vm.expectRevert("Governor: AI may only propose technical parameters");
        governor.propose(
            ElysiumGovernor.ProposalType.TreasurySpendSmall,
            "Spend",
            targets,
            values,
            calldatas
        );
    }

    function test_AI_Phase2_Propose_Constitutional_Reverts() public {
        // Wait 30 days before phase transition
        vm.warp(block.timestamp + 30 days);
        citizenshipNFT.updatePhase(aiTokenId, 2);

        address[] memory targets = new address[](1);
        targets[0] = address(0);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";

        vm.prank(aiWallet);
        vm.expectRevert("Governor: AI cannot propose constitutional/core changes");
        governor.propose(
            ElysiumGovernor.ProposalType.Constitutional,
            "Const",
            targets,
            values,
            calldatas
        );
    }
}
