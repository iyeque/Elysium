// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";

// Mock operator registry for CitizenshipNFT constructor
contract MockOperatorRegistry {
    function verifyAttestation(address, address) external pure returns (bool valid, uint256 count) {
        return (true, 0);
    }
}

contract CitizenshipNFTPhaseTransitionTest is Test {
    CitizenshipNFT citizenshipNFT;
    address admin = address(this);
    address h1Wallet = address(0x2);
    address h2Wallet = address(0x3);
    address h3Wallet = address(0x4);
    uint256 h1TokenId;
    uint256 h2TokenId;
    uint256 h3TokenId;

    MockOperatorRegistry mockOperatorRegistry;

    function setUp() public {
        mockOperatorRegistry = new MockOperatorRegistry();
        citizenshipNFT = new CitizenshipNFT(address(mockOperatorRegistry));
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), admin);
        citizenshipNFT.grantRole(citizenshipNFT.VERIFIER_ROLE(), admin);

        // Mint humans with initial phases
        vm.prank(admin);
        h1TokenId = citizenshipNFT.mintHuman(h1Wallet, 2, 1, ""); // H1
        h2TokenId = citizenshipNFT.mintHuman(h2Wallet, 2, 2, ""); // H2
        h3TokenId = citizenshipNFT.mintHuman(h3Wallet, 2, 3, ""); // H3 (already phase 3 - for signer tests later if needed)
    }

    function wait30Days() internal {
        vm.warp(block.timestamp + 30 days);
    }

    // --- 30-day cooldown and progression tests ---

    function test_PhaseTransitionRequires30Days() public {
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizen(h1TokenId);
        assertEq(c.phase, 1);
        vm.prank(admin);
        vm.expectRevert("Citizenship: 30-day waiting period not elapsed");
        citizenshipNFT.updatePhase(h1TokenId, 2);
    }

    function test_PhaseTransitionRequiresIncrementByOne() public {
        wait30Days();
        vm.prank(admin);
        vm.expectRevert("Citizenship: invalid phase transition (must increment by 1)");
        citizenshipNFT.updatePhase(h1TokenId, 3); // try skip from 1 to 3
    }

    function test_PhaseTransitionProgressionWorks() public {
        // 1 -> 2
        wait30Days();
        vm.prank(admin);
        citizenshipNFT.updatePhase(h1TokenId, 2);
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizen(h1TokenId);
        assertEq(c.phase, 2);
        uint256 phase2Time = c.phaseLastUpdated;

        // Wait another 30 days, then 2 -> 3
        vm.warp(phase2Time + 30 days);
        vm.prank(admin);
        citizenshipNFT.updatePhase(h1TokenId, 3);
        c = citizenshipNFT.getCitizen(h1TokenId);
        assertEq(c.phase, 3);
    }

    // --- H3 cannot be added as signer (tested via CitizenshipJury) ---
    // We'll add a minimal check that H3 phase is not eligible for signer role by verifying _checkEligibility indirectly through addSigner.
    // Note: This test requires a CitizenshipJury instance; we can skip it here to keep this test isolated to CitizenshipNFT.
    // The existing CitizenshipJury tests (via _checkEligibility) already block H3.
}
