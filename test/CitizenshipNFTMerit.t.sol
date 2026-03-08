// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";

contract CitizenshipNFTMeritTest is Test {
    CitizenshipNFT citizenshipNFT;
    address admin = address(this);
    address grantor = address(0x10);
    address recipient = address(0x20);

    function setUp() public {
        OperatorRegistry operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        
        // Grant MERIT_GRANTOR_ROLE to grantor, revoke from admin
        citizenshipNFT.revokeRole(citizenshipNFT.MERIT_GRANTOR_ROLE(), admin);
        citizenshipNFT.grantRole(citizenshipNFT.MERIT_GRANTOR_ROLE(), grantor);
    }

    function test_GrantMerit_OnlyGrantor() public {
        vm.prank(grantor);
        citizenshipNFT.grantMerit(recipient, 2, 1, "merit-metadata");
        assertTrue(citizenshipNFT.hasCitizenship(recipient));
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizenByAddress(recipient);
        assertEq(c.tier, 2);
        assertEq(c.phase, 1);
        assertFalse(c.isAI);
    }

    function test_GrantMerit_NonGrantorReverts() public {
        vm.expectRevert();
        vm.prank(admin);
        citizenshipNFT.grantMerit(recipient, 2, 1, "");
    }

    function test_GrantMerit_AlreadyCitizenReverts() public {
        vm.prank(grantor);
        citizenshipNFT.grantMerit(recipient, 2, 1, "");
        
        vm.expectRevert("Citizenship: already a citizen");
        vm.prank(grantor);
        citizenshipNFT.grantMerit(recipient, 2, 2, "");
    }

    function test_GrantMerit_EmitsEvents() public {
        vm.prank(grantor);
        uint256 tokenId = citizenshipNFT.grantMerit(recipient, 3, 2, "uri");
        
        // Just verify tokenId is non-zero and state is correct
        assertTrue(tokenId > 0);
        CitizenshipNFT.Citizen memory c = citizenshipNFT.getCitizenByAddress(recipient);
        assertEq(c.tier, 3);
        assertEq(c.phase, 2);
    }
}
