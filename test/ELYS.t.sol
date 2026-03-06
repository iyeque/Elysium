 // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.20;

   import { Test } from "forge-std/Test.sol";
   import { ELYS } from "../contracts/ELYS.sol";

   contract ELYSTest is Test {
       ELYS elys;
       address owner = address(0x1);
       address user1 = address(0x2);
       address user2 = address(0x3);

       function setUp() public {
           elys = new ELYS();
           // Deployer (this) has all tokens; transfer some to owner
           uint256 initial = 1_000_000 * 10**18;
           vm.prank(address(this));
           elys.transfer(owner, initial);
       }

       function test_MintMaxSupply() public {
           assertEq(elys.totalSupply(), elys.MAX_SUPPLY());
       }

       function test_Transfer() public {
           uint256 amount = 1000 * 10**18;
           vm.prank(owner);
           elys.transfer(user1, amount);
           assertEq(elys.balanceOf(user1), amount);
           assertEq(elys.balanceOf(owner), 1_000_000 * 10**18 - amount);
       }
   }