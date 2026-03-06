// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ElysiumGovernor } from "../contracts/ElysiumGovernor.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract ElysiumGovernorH3DelayTest is Test {
    ElysiumGovernor governor;
    CitizenshipNFT citizenshipNFT;
    OperatorRegistry operatorRegistry;
    TimelockController timelock;
    
    address admin = address(this);
    address h1 = address(0x2);
    address h2 = address(0x3);
    address h3 = address(0x4);
    
    function setUp() public {
        operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        
        // Grant MINTER to test contract
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), address(this));
        
        // Mint humans: H1 (phase1), H2 (phase2), H3 (phase3), all Resident tier (1)
        citizenshipNFT.mintHuman(h1, 1, 1, "");
        citizenshipNFT.mintHuman(h2, 1, 2, "");
        citizenshipNFT.mintHuman(h3, 1, 3, "");
        
        // Deploy TimelockController with 1 day delay, empty proposers/executors, admin is test contract
        timelock = new TimelockController(1 days, new address[](0), new address[](0), address(this));
        
        // Governor will be set as proposer/executor after deployment
        governor = new ElysiumGovernor(citizenshipNFT, timelock, "Elysium");
        
        // Grant timelock roles to governor (admin is test contract)
        vm.prank(admin);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        vm.prank(admin);
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
    }

    function test_H3Before6MonthsHasZeroVotes() public {
        // H3 just minted, so createdAt is now, not yet 6 months
        uint256 votes = governor.getVotes(h3, block.number);
        assertEq(votes, 0);
    }

    function test_H3After6MonthsHasOneVote() public {
        // Warp forward 183 days
        vm.warp(block.timestamp + 183 days);
        // Also advance block number to ensure snapshot block is after warp
        // (block.number increases automatically on warp? We may need to also increase block.number via `vm.roll`? Actually `vm.warp` sets block.timestamp, but block.number remains the same unless we also roll. However `getVotes` takes blockNumber as argument; we pass block.number (current). Since block.number hasn't changed, but timestamp changed. Our check uses block.timestamp, which is warped. So it should be fine.
        uint256 votes = governor.getVotes(h3, block.number);
        assertEq(votes, 1 ether);
    }

    function test_H1AndH2AlwaysHaveVote() public {
        assertEq(governor.getVotes(h1, block.number), 1 ether);
        assertEq(governor.getVotes(h2, block.number), 1 ether);
    }
}
