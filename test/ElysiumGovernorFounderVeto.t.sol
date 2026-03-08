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

contract ElysiumGovernorFounderVetoTest is Test {
    ElysiumGovernor governor;
    CitizenshipNFT citizenshipNFT;
    MockOperatorRegistry mockOperatorRegistry;
    TimelockController timelock;

    address admin = address(this);
    address founder = address(0x1);
    address human1 = address(0x2);
    address nonFounder = address(0x4);
    
    uint256 human1TokenId;

    function setUp() public {
        mockOperatorRegistry = new MockOperatorRegistry();
        citizenshipNFT = new CitizenshipNFT(address(mockOperatorRegistry));
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), admin);
        
        timelock = new TimelockController(2 days, new address[](0), new address[](0), admin);
        governor = new ElysiumGovernor(citizenshipNFT, timelock, "Elysium", founder);
        
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
        
        vm.prank(admin);
        human1TokenId = citizenshipNFT.mintHuman(human1, 1, 1, "");
        citizenshipNFT.updateTier(human1TokenId, 1);
    }

    function test_FounderCanVeto() public {
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test proposal",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(human1);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod());
        
        vm.prank(human1);
        bytes32 descriptionHash = keccak256(bytes("Test proposal#ParameterChange"));
        governor.queue(_buildTargets(address(0)), _buildValues(0), _buildCalldatas(""), descriptionHash);
        
        uint256 eta = governor.proposalEta(proposalId);
        vm.warp(eta - 24 hours);
        
        vm.prank(founder);
        governor.vetoProposal(proposalId);
        
        assertTrue(governor.proposalVetoed(proposalId));
    }

    function test_NonFounderCannotVeto() public {
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(human1);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod());
        bytes32 descriptionHash = keccak256(bytes("Test#ParameterChange"));
        vm.prank(human1);
        governor.queue(_buildTargets(address(0)), _buildValues(0), _buildCalldatas(""), descriptionHash);
        uint256 eta = governor.proposalEta(proposalId);
        vm.warp(eta - 24 hours);
        
        vm.prank(nonFounder);
        vm.expectRevert(); // any revert is acceptable; nonFounder should not have FOUNDER_ROLE
        governor.vetoProposal(proposalId);
    }

    function test_VetoFailsTooEarly() public {
        // Set a sufficiently large base timestamp so that eta - 72 hours is still positive
        // (Avoid underflow when computing eta - 72h)
        uint256 baseTimestamp = 1_000_000;
        vm.warp(baseTimestamp);
        
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(human1);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod());
        bytes32 descriptionHash = keccak256(bytes("Test#ParameterChange"));
        vm.prank(human1);
        governor.queue(_buildTargets(address(0)), _buildValues(0), _buildCalldatas(""), descriptionHash);
        uint256 eta = governor.proposalEta(proposalId);
        // Now warp to 72 hours before eta (which is safely before the 48h veto window)
        vm.warp(eta - 72 hours);
        
        vm.prank(founder);
        vm.expectRevert("Governor: veto only allowed within 48h of execution");
        governor.vetoProposal(proposalId);
    }

    function test_VetoFailsAfterExecutionTime() public {
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(human1);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod());
        bytes32 descriptionHash = keccak256(bytes("Test#ParameterChange"));
        vm.prank(human1);
        governor.queue(_buildTargets(address(0)), _buildValues(0), _buildCalldatas(""), descriptionHash);
        uint256 eta = governor.proposalEta(proposalId);
        vm.warp(eta + 1);
        
        vm.prank(founder);
        vm.expectRevert("Governor: veto only allowed within 48h of execution");
        governor.vetoProposal(proposalId);
    }

    function test_VetoFailsAfterSunset() public {
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        vm.roll(block.number + governor.votingDelay() + 1);
        vm.prank(human1);
        governor.castVote(proposalId, 1);
        vm.roll(block.number + governor.votingPeriod());
        bytes32 descriptionHash = keccak256(bytes("Test#ParameterChange"));
        vm.prank(human1);
        governor.queue(_buildTargets(address(0)), _buildValues(0), _buildCalldatas(""), descriptionHash);
        
        uint256 current = block.timestamp;
        vm.warp(current + 3 * 365 days + 1 days);
        
        vm.prank(founder);
        vm.expectRevert("Governor: veto window has sunset");
        governor.vetoProposal(proposalId);
    }

    function test_VetoFailsNotQueued() public {
        vm.prank(human1);
        uint256 proposalId = governor.propose(
            ElysiumGovernor.ProposalType.ParameterChange,
            "Test",
            _buildTargets(address(0)),
            _buildValues(0),
            _buildCalldatas("")
        );
        
        vm.prank(founder);
        vm.expectRevert("Governor: proposal not queued");
        governor.vetoProposal(proposalId);
    }

    function _buildTargets(address target) internal pure returns (address[] memory) {
        address[] memory targets = new address[](1);
        targets[0] = target;
        return targets;
    }
    
    function _buildValues(uint256 value) internal pure returns (uint256[] memory) {
        uint256[] memory values = new uint256[](1);
        values[0] = value;
        return values;
    }
    
    function _buildCalldatas(bytes memory calldata_) internal pure returns (bytes[] memory) {
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = calldata_;
        return calldatas;
    }
}
