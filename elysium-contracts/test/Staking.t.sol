 // SPDX-License-Identifier: UNLICENSED
   pragma solidity ^0.8.20;

   import { Test } from "forge-std/Test.sol";
   import { Staking } from "../contracts/Staking.sol";
   import { ELYS } from "../contracts/ELYS.sol";
   import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
   import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";

   contract StakingTest is Test {
       Staking staking;
       ELYS elys;
       CitizenshipNFT citizenshipNFT;
       OperatorRegistry operatorRegistry;

       address admin = address(this);
       address user = address(0x2);

       function setUp() public {
           elys = new ELYS();
           operatorRegistry = new OperatorRegistry(address(0));
           citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
           staking = new Staking(address(elys), address(citizenshipNFT));

           // Grant MINTER_ROLE to staking on citizenshipNFT
           vm.prank(admin);
           citizenshipNFT.grantRole(bytes32(keccak256("MINTER_ROLE")), address(staking));
       }

       function test_StakeTokens() public {
           uint256 amount = 10000 * 10**18;
           vm.prank(admin);
           elys.transfer(user, amount);
           vm.prank(user);
           elys.approve(address(staking), amount);
           vm.prank(user);
           staking.stake(amount);
           assertEq(staking.balanceOf(user), amount);
       }

       function test_LockPeriod() public {
           uint256 amount = 10000 * 10**18;
           vm.prank(admin);
           elys.transfer(user, amount);
           vm.prank(user);
           elys.approve(address(staking), amount);
           vm.prank(user);
           staking.stake(amount);
           vm.expectRevert("Staking: still locked");
           vm.prank(user);
           staking.requestUnstake(0);
       }
   }