// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";

contract CitizenshipNFTVerifierTest is Test {
    CitizenshipNFT citizenshipNFT;
    OperatorRegistry operatorRegistry;
    address admin = address(this);
    address verifier = address(0x10);
    address nonVerifier = address(0x11);
    address citizen = address(0x20);

    function setUp() public {
        operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        
        // Revoke VERIFIER_ROLE from admin (only keep for verifier)
        citizenshipNFT.revokeRole(citizenshipNFT.VERIFIER_ROLE(), admin);
        
        // Grant VERIFIER_ROLE to verifier only
        citizenshipNFT.grantRole(citizenshipNFT.VERIFIER_ROLE(), verifier);
        
        // Mint a citizen
        vm.prank(admin);
        citizenshipNFT.mintHuman(citizen, 2, 1, "");
    }

    function test_OnlyVerifierCanVerify() public {
        vm.prank(verifier);
        citizenshipNFT.verifyHumanPhase(citizen, 2);
        assertTrue(citizenshipNFT.isVerified(citizen));

        // Non-verifier cannot verify
        vm.prank(nonVerifier);
        vm.expectRevert();
        citizenshipNFT.verifyHumanPhase(citizen, 2);
    }

    function test_VerifyUpdatesPhase() public {
        vm.prank(verifier);
        citizenshipNFT.verifyHumanPhase(citizen, 2);
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizenByAddress(citizen);
        assertEq(c.phase, 2);
        assertEq(c.tier, 2);
    }

    function test_VerifyMultipleTimes() public {
        vm.prank(verifier);
        citizenshipNFT.verifyHumanPhase(citizen, 2);
        vm.prank(verifier);
        citizenshipNFT.verifyHumanPhase(citizen, 3); // update to phase 3

        assertTrue(citizenshipNFT.isVerified(citizen));
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizenByAddress(citizen);
        assertEq(c.phase, 3);
    }

    function test_VerifyNonCitizen_Reverts() public {
        vm.prank(verifier);
        vm.expectRevert("Citizenship: not a citizen");
        citizenshipNFT.verifyHumanPhase(address(0x99), 2);
    }
}