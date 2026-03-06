// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { ElysiumTreasuryMultiSig } from "../contracts/ElysiumTreasuryMultiSig.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";
import { OperatorRegistry } from "../contracts/OperatorRegistry.sol";

contract TreasuryAnnualCapTest is Test {
    ElysiumTreasuryMultiSig treasury;
    CitizenshipNFT citizenshipNFT;
    OperatorRegistry operatorRegistry;
    
    address signer1 = address(0x2);
    address signer2 = address(0x3);
    address signer3 = address(0x4);
    address signer4 = address(0x5);
    address signer5 = address(0x6);
    
    function setUp() public {
        operatorRegistry = new OperatorRegistry(address(0));
        citizenshipNFT = new CitizenshipNFT(address(operatorRegistry));
        
        // Test contract is DEFAULT_ADMIN; grant MINTER to itself
        citizenshipNFT.grantRole(citizenshipNFT.MINTER_ROLE(), address(this));
        
        // Mint eligible signers: H1 or H2, tier 1
        citizenshipNFT.mintHuman(signer1, 1, 1, "");
        citizenshipNFT.mintHuman(signer2, 1, 1, "");
        citizenshipNFT.mintHuman(signer3, 1, 1, "");
        citizenshipNFT.mintHuman(signer4, 2, 1, ""); // H2
        citizenshipNFT.mintHuman(signer5, 1, 1, "");
        
        // Deploy treasury with 5 signers, 3 required
        address[] memory initialSigners = new address[](5);
        initialSigners[0] = signer1;
        initialSigners[1] = signer2;
        initialSigners[2] = signer3;
        initialSigners[3] = signer4;
        initialSigners[4] = signer5;
        
        treasury = new ElysiumTreasuryMultiSig(initialSigners, address(this), address(citizenshipNFT));
        
        // Fund treasury with ETH
        vm.deal(address(treasury), 100 ether);
    }

    function _submitAndGetTxId(address submitter, address recipient, uint256 amount) internal returns (uint256) {
        uint256 before = treasury.nextTransactionId();
        vm.prank(submitter);
        treasury.submitTransaction(recipient, amount, "");
        return before; // txId = before
    }

    function test_SpendWithinCapSucceeds() public {
        uint256 amount = 5 ether;
        address payable recipient = payable(address(0x99));
        
        // Submit by signer1 gives 1 auto-confirm; need 2 more (total 3/5=60%
        uint256 txId = _submitAndGetTxId(signer1, recipient, amount);
        
        vm.prank(signer2);
        treasury.confirmTransaction(txId);
        vm.prank(signer3);
        treasury.confirmTransaction(txId);
        
        // Execute by signer1
        vm.prank(signer1);
        treasury.executeTransaction(txId);
        
        assertEq(payable(recipient).balance, amount);
    }

    function test_SpendExceedsCapWithoutSupermajorityFails() public {
        uint256 amount = 15 ether; // > 10% of 100 ETH
        address payable recipient = payable(address(0x99));
        
        uint256 txId = _submitAndGetTxId(signer1, recipient, amount);
        
        // Need 3 approvals total (60%) to test failure: submitter auto, plus signer2 and signer3 -> total 3
        vm.prank(signer2);
        treasury.confirmTransaction(txId);
        vm.prank(signer3);
        treasury.confirmTransaction(txId);
        
        vm.prank(signer1);
        vm.expectRevert("Treasury: annual cap exceeded without supermajority");
        treasury.executeTransaction(txId);
    }

    function test_SpendExceedsCapWithSupermajoritySucceeds() public {
        uint256 amount = 15 ether;
        address payable recipient = payable(address(0x99));
        
        uint256 txId = _submitAndGetTxId(signer1, recipient, amount);
        
        // Need 4 approvals total (80%): submitter auto + signer2, signer3, signer4 (3 additional) = 4
        vm.prank(signer2);
        treasury.confirmTransaction(txId);
        vm.prank(signer3);
        treasury.confirmTransaction(txId);
        vm.prank(signer4);
        treasury.confirmTransaction(txId);
        
        vm.prank(signer1);
        treasury.executeTransaction(txId);
        
        assertEq(payable(recipient).balance, amount);
    }

    function test_FiscalYearResetClearsAnnualSpend() public {
        uint256 spend1 = 5 ether;
        address payable recipient = payable(address(0x99));
        uint256 txId1 = _submitAndGetTxId(signer1, recipient, spend1);
        vm.prank(signer2); treasury.confirmTransaction(txId1);
        vm.prank(signer3); treasury.confirmTransaction(txId1);
        vm.prank(signer1); treasury.executeTransaction(txId1);
        
        assertEq(treasury.annualSpend(), spend1);
        
        // Advance time by more than a year
        vm.warp(block.timestamp + 366 days);
        
        uint256 spend2 = 1 ether;
        uint256 txId2 = _submitAndGetTxId(signer1, recipient, spend2);
        vm.prank(signer2); treasury.confirmTransaction(txId2);
        vm.prank(signer3); treasury.confirmTransaction(txId2);
        vm.prank(signer1); treasury.executeTransaction(txId2);
        
        assertEq(treasury.annualSpend(), spend2);
    }

    function test_GetRemainingCap() public {
        // No spend yet; remaining cap is full 10% of treasury balance
        uint256 treasuryBalance = address(treasury).balance;
        uint256 cap = (treasuryBalance * 1000) / 10000; // 10%
        assertEq(treasury.getRemainingCap(), cap);
    }

    function test_MultipleSpendWithinCapAccumulates() public {
        uint256 spend1 = 3 ether;
        uint256 spend2 = 4 ether; // total 7 < 10% of 100 ETH (which is 10 ETH)
        address payable recipient = payable(address(0x99));
        
        // First transaction: submit + 2 confirms
        uint256 txId1 = _submitAndGetTxId(signer1, recipient, spend1);
        vm.prank(signer2); treasury.confirmTransaction(txId1);
        vm.prank(signer3); treasury.confirmTransaction(txId1);
        vm.prank(signer1); treasury.executeTransaction(txId1);
        
        // Second transaction: submit + 2 confirms
        uint256 txId2 = _submitAndGetTxId(signer1, recipient, spend2);
        vm.prank(signer2); treasury.confirmTransaction(txId2);
        vm.prank(signer3); treasury.confirmTransaction(txId2);
        vm.prank(signer1); treasury.executeTransaction(txId2);
        
        assertEq(treasury.annualSpend(), spend1 + spend2);
    }
}
