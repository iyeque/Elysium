// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Staking } from "../contracts/Staking.sol";
import { ELYS } from "../contracts/ELYS.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";

contract StakingRewardsTest is Test {
    Staking staking;
    ELYS elys;
    CitizenshipNFT citizenshipNFT;
    OperatorRegistry operatorRegistry;

    address admin = address(this);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        elys = new ELYS(address(0));
        operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));

        // Ensure test contract has DEFAULT_ADMIN (granted in constructor) and grant MINTER to staking
        staking = new Staking(address(elys), address(citizenshipNFT));

        // Grant REWARDER_ROLE on Staking to admin for adding rewards
        vm.prank(admin);
        staking.grantRole(keccak256("REWARDER_ROLE"), admin);

        // Grant MINTER_ROLE on CitizenshipNFT to Staking so it can mint
        bytes32 minterRole = citizenshipNFT.MINTER_ROLE();
        citizenshipNFT.grantRole(minterRole, address(staking));

        // Verify role granted
        assertTrue(citizenshipNFT.hasRole(minterRole, address(staking)));

        // Setup: give users tokens and approve staking
        uint256 amount1 = 10_000 * 10**18;
        uint256 amount2 = 10_000 * 10**18;
        vm.prank(admin);
        elys.transfer(user1, amount1);
        vm.prank(admin);
        elys.transfer(user2, amount2);

        vm.prank(user1);
        elys.approve(address(staking), amount1);
        vm.prank(user2);
        elys.approve(address(staking), amount2);
    }

    function test_AddRewardsAndClaim() public {
        uint256 rewardAmount = 1000 * 10**18;
        vm.prank(admin);
        staking.addRewards(rewardAmount);

        // user1 stakes
        vm.prank(user1);
        staking.stake(10_000 * 10**18);

        // Add another reward after stake
        vm.prank(admin);
        staking.addRewards(rewardAmount);

        // user1 claims
        vm.prank(user1);
        staking.claimRewards();

        // user1 should have received both rewards (only staker)
        assertEq(elys.balanceOf(user1), rewardAmount * 2);
    }

    function test_RewardPerTokenDistribution() public {
        uint256 rewardAmount = 1000 * 10**18;

        // Add first reward before any stake -> pending
        vm.prank(admin);
        staking.addRewards(rewardAmount);

        // user1 stakes first
        vm.prank(user1);
        staking.stake(10_000 * 10**18);

        // Add second reward (only user1 staked)
        vm.prank(admin);
        staking.addRewards(rewardAmount);

        // user2 stakes
        vm.prank(user2);
        staking.stake(10_000 * 10**18);

        // Add third reward (both staked)
        vm.prank(admin);
        staking.addRewards(rewardAmount);

        // Claim for user1
        vm.prank(user1);
        staking.claimRewards();
        // user1 gets: first reward (distributed on stake) + second reward (full) + half of third
        uint256 expectedUser1 = rewardAmount + rewardAmount + rewardAmount / 2;
        assertEq(elys.balanceOf(user1), expectedUser1);

        // Claim for user2
        vm.prank(user2);
        staking.claimRewards();
        // user2 gets only half of third reward
        assertEq(elys.balanceOf(user2), rewardAmount / 2);
    }

    function test_PendingRewardsWhenNoStake() public {
        uint256 rewardAmount = 1000 * 10**18;
        vm.prank(admin);
        staking.addRewards(rewardAmount);
        // Pending rewards because no stake

        vm.prank(user1);
        staking.stake(10_000 * 10**18);
        // Pending rewards distributed to first staker

        vm.prank(user1);
        staking.claimRewards();
        assertEq(elys.balanceOf(user1), rewardAmount);
    }

    function test_NoClaimWhenNoRewards() public {
        vm.prank(user1);
        staking.stake(10_000 * 10**18);
        vm.expectRevert("Staking: no rewards");
        vm.prank(user1);
        staking.claimRewards();
    }
}
