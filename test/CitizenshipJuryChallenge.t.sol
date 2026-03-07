// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CitizenshipJury } from "../contracts/CitizenshipJury.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";
import { ELYS } from "../contracts/ELYS.sol";

contract CitizenshipJuryChallengeTest is Test {
    CitizenshipJury jury;
    CitizenshipNFT citizenshipNFT;
    OperatorRegistry operatorRegistry;
    ELYS elys;
    uint256 private constant CHALLENGE_DEPOSIT = 1000 * 1e18;

    address admin = address(this);
    address challenger = address(0x10);
    address[] jurors; // will be populated in setUp

    uint256 targetTokenId;

    function setUp() public {
        // Deploy ELYS
        elys = new ELYS(address(0));
        // Transfer ELYS to participants (deployer is initial holder)
        vm.prank(admin);
        elys.transfer(challenger, 10000 * 1e18);
        // We'll also transfer to jurors later after we know their addresses
    }

    function _deployAndSetupCitizens() internal {
        // Deploy OperatorRegistry and CitizenshipNFT
        operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        // Grant MINTER to admin
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), admin);
        // Grant JURY_ROLE to jury later

        // Prepare jurors: we need at least 6 eligible addresses (so we can pick 5 distinct from challenger)
        jurors = new address[](6);
        jurors[0] = address(0x11);
        jurors[1] = address(0x12);
        jurors[2] = address(0x13);
        jurors[3] = address(0x14);
        jurors[4] = address(0x15);
        jurors[5] = address(0x16);

        // Mint each juror as Citizen tier (2), H1 (phase=1)
        for (uint256 i = 0; i < jurors.length; i++) {
            citizenshipNFT.mintHuman(jurors[i], 2, 1, "");
            // Transfer ELYS to each juror
            vm.prank(admin);
            elys.transfer(jurors[i], 10000 * 1e18);
        }

        // Deploy CitizenshipJury: need initial signers to satisfy constructor (>=3). Use first 3 jurors as signers.
        address[] memory initialSigners = new address[](3);
        initialSigners[0] = jurors[0];
        initialSigners[1] = jurors[1];
        initialSigners[2] = jurors[2];
        jury = new CitizenshipJury(initialSigners, admin, address(citizenshipNFT), address(elys));

        // Grant JURY_ROLE on CitizenshipNFT to jury contract
        citizenshipNFT.grantRole(citizenshipNFT.JURY_ROLE(), address(jury));

        // Create a target citizen to challenge (different from challenger and jurors)
        address target = address(0x20);
        citizenshipNFT.mintHuman(target, 2, 1, "");
        targetTokenId = citizenshipNFT.citizenTokenId(target);
    }

    function test_ChallengeAndRevoke_Success() public {
        _deployAndSetupCitizens();

        // Challenger approves deposit to jury
        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);

        // Create challenge
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);

        uint256 challengeId = 1;
        CitizenshipJury.Challenge memory c = jury.getChallenge(challengeId);
        assertEq(c.tokenId, targetTokenId);
        assertEq(c.challenger, challenger);
        assertEq(c.executed, false);
        assertEq(c.votesFor, 0);
        assertEq(c.votesAgainst, 0);

        // Get selected jurors
        address[] memory selected = jury.getJurors(challengeId);
        assertEq(selected.length, 5); // MAX_SIGNERS = 5
        // Ensure challenger not among selected
        for (uint256 i = 0; i < selected.length; i++) {
            assert(selected[i] != challenger);
        }

        // Selected jurors vote to revoke (support)
        for (uint256 i = 0; i < 3; i++) { // only need 3 votes to reach threshold
            vm.prank(selected[i]);
            jury.vote(challengeId, true);
        }

        // Finalize: should succeed with majority for (3>0) -> revoke
        vm.prank(selected[0]);
        jury.finalizeChallenge(challengeId);

        // Verify citizenship revoked
        vm.expectRevert();
        citizenshipNFT.ownerOf(targetTokenId);
        // Verify deposit burned: transferred to address(0)
        assertEq(elys.balanceOf(jury.BURN_ADDRESS()), CHALLENGE_DEPOSIT);
        // Check challenge executed flag and revoked
        c = jury.getChallenge(challengeId);
        assertEq(c.executed, true);
    }

    function test_ChallengeAndRefund_Success() public {
        _deployAndSetupCitizens();

        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);

        uint256 challengeId = 1;
        address[] memory selected = jury.getJurors(challengeId);
        assertEq(selected.length, 5);

        // Jurors vote against revocation
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(selected[i]);
            jury.vote(challengeId, false);
        }

        // Finalize: should refund deposit because votesAgainst > votesFor (3>0)
        vm.prank(selected[0]);
        jury.finalizeChallenge(challengeId);

        // Citizenship should not be revoked
        assert(citizenshipNFT.ownerOf(targetTokenId) != address(0));
        // Deposit returned to challenger
        assertEq(elys.balanceOf(challenger), 10000 * 1e18);
    }

    function test_OnlyJurorsCanVote() public {
        _deployAndSetupCitizens();
        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);
        uint256 challengeId = 1;
        address[] memory selected = jury.getJurors(challengeId);

        // Non-juror attempts to vote -> revert
        vm.expectRevert("CitizenshipJury: not a juror");
        vm.prank(address(0x99)); // random address
        jury.vote(challengeId, true);
    }

    function test_DuplicateVoteReverts() public {
        _deployAndSetupCitizens();
        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);
        uint256 challengeId = 1;
        address[] memory selected = jury.getJurors(challengeId);

        vm.prank(selected[0]);
        jury.vote(challengeId, true);
        // Second vote from same juror
        vm.expectRevert("CitizenshipJury: already voted");
        vm.prank(selected[0]);
        jury.vote(challengeId, false);
    }

    function test_FinalizeBeforeEnoughVotesReverts() public {
        _deployAndSetupCitizens();
        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);
        uint256 challengeId = 1;
        address[] memory selected = jury.getJurors(challengeId);

        // Only 2 votes (need 3)
        vm.prank(selected[0]);
        jury.vote(challengeId, true);
        vm.prank(selected[1]);
        jury.vote(challengeId, true);

        vm.expectRevert("CitizenshipJury: not enough votes");
        vm.prank(selected[0]);
        jury.finalizeChallenge(challengeId);
    }

    function test_CannotChallengeSameTokenTwice() public {
        _deployAndSetupCitizens();
        vm.prank(challenger);
        elys.approve(address(jury), CHALLENGE_DEPOSIT);
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);
        // Second challenge
        vm.expectRevert("CitizenshipJury: already challenged");
        vm.prank(challenger);
        jury.createChallenge(targetTokenId);
    }
}
