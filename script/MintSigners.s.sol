// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { CitizenshipNFT } from "../contracts/CitizenshipNFT.sol";

contract MintSigners is Script {
    CitizenshipNFT public citizenshipNFT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address nftAddr = vm.envAddress("CITIZENSHIP_NFT");
        citizenshipNFT = CitizenshipNFT(nftAddr);

        string memory csv = vm.envString("SIGNER_ADDRESSES");
        require(bytes(csv).length > 0, "Set SIGNER_ADDRESSES env var (comma-separated)");

        address[] memory signers = _parseAddresses(csv);

        for (uint256 i = 0; i < signers.length; i++) {
            citizenshipNFT.mintHuman(signers[i], 3, 1, "");
            console.log("Minted", signers[i]);
        }

        vm.stopBroadcast();
        console.log("Done. Minted", signers.length, "signers.");
    }

    function _parseAddresses(string memory csv) internal pure returns (address[] memory) {
        bytes memory b = bytes(csv);
        uint256 count = 1;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ',') count++;
        }
        address[] memory result = new address[](count);
        uint256 start = 0;
        uint256 idx = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ',') {
                result[idx] = _parseAddr(string(abi.encodePacked(b[start:i])));
                start = i + 1;
                idx++;
            }
        }
        result[idx] = _parseAddr(string(abi.encodePacked(b[start:b.length])));
        return result;
    }

    function _parseAddr(string memory hexStr) internal pure returns (address) {
        bytes memory b = bytes(hexStr);
        require(b.length == 42 && b[0] == '0' && b[1] == 'x', "bad addr");
        bytes20 a;
        for (uint256 i = 0; i < 20; i++) {
            a[i] = bytes1(uint8((_hex(b[2+i*2]) << 4) + _hex(b[3+i*2])));
        }
        return address(a);
    }

    function _hex(uint8 c) internal pure returns (uint8) {
        if (c >= 48 && c <= 57) return c - 48;
        if (c >= 97 && c <= 102) return c - 87;
        if (c >= 65 && c <= 70) return c - 55;
        revert("bad hex");
    }
}
