// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ElysiumGovernor } from "../contracts/ElysiumGovernor.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

contract MockOperatorRegistry {
    function verifyAttestation(address, address) external pure returns (bool valid, uint256 count) {
        return (true, 0);
    }
}

contract ElysiumTierTimelocksTest is Test {
    ElysiumGovernor governor;
    CitizenshipNFT citizenshipNFT;
    MockOperatorRegistry mockOperatorRegistry;
    TimelockController timelock;

    address admin = address(this);
    address proposer = address(0x2);
    uint256 proposerTokenId;

    function setUp() public {
        mockOperatorRegistry = new MockOperatorRegistry();
        citizenshipNFT = new CitizenshipNFT(address(mockOperatorRegistry));
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), admin);
        
        timelock = new TimelockController(1 days, new address[](0), new address[](0), admin);
        governor = new ElysiumGovernor(citizenshipNFT, timelock, "Elysium", admin);
        
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
        
        // Mint a human citizen with Resident tier (1)
        vm.prank(admin);
        proposerTokenId = citizenshipNFT.mintHuman(proposer, 1, 1, "");
        citizenshipNFT.updateTier(proposerTokenId, 1);
    }

    function test_Tier1Timelocks() public {
        // ParameterChange is Tier1: votingDelay = 1 day, votingPeriod = 7 days
        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Tier1 Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        
        uint256 expectedDelay = 1 days;
        uint256 expectedPeriod = 7 days;
        
        uint256 snapshot = governor.proposalSnapshot(proposalId);
        uint256 deadline = governor.proposalDeadline(proposalId);
        
        assertEq(snapshot, block.number + expectedDelay, "Tier1: snapshot should be block.number + 1 day");
        assertEq(deadline, snapshot + expectedPeriod, "Tier1: deadline should be snapshot + 7 days");
    }

    function test_Tier2Timelocks() public {
        // TreasurySpendMedium is Tier2: votingDelay = 7 days, votingPeriod = 7 days
        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.TreasurySpendMedium,
            "Tier2 Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        
        uint256 expectedDelay = 7 days;
        uint256 expectedPeriod = 7 days;
        
        uint256 snapshot = governor.proposalSnapshot(proposalId);
        uint256 deadline = governor.proposalDeadline(proposalId);
        
        assertEq(snapshot, block.number + expectedDelay, "Tier2: snapshot should be block.number + 7 days");
        assertEq(deadline, snapshot + expectedPeriod, "Tier2: deadline should be snapshot + 7 days");
    }

    function test_Tier3Timelocks() public {
        // Constitutional is Tier3: votingDelay = 14 days, votingPeriod = 10 days
        vm.prank(proposer);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.Constitutional,
            "Tier3 Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        
        uint256 expectedDelay = 14 days;
        uint256 expectedPeriod = 10 days;
        
        uint256 snapshot = governor.proposalSnapshot(proposalId);
        uint256 deadline = governor.proposalDeadline(proposalId);
        
        assertEq(snapshot, block.number + expectedDelay, "Tier3: snapshot should be block.number + 14 days");
        assertEq(deadline, snapshot + expectedPeriod, "Tier3: deadline should be snapshot + 10 days");
    }

    // Helper functions to build empty arrays
    function _buildTargets(address addr) internal pure returns (address[] memory) {
        address[] memory targets = new address[](1);
        targets[0] = addr;
        return targets;
    }
    
    function _buildValues(uint256 val) internal pure returns (uint256[] memory) {
        uint256[] memory values = new uint256[](1);
        values[0] = val;
        return values;
    }
    
    function _buildCalldatas(string memory) internal pure returns (bytes[] memory) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        return calldatas;
    }
}
