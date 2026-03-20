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
        if (b.length == 0) return new address[](0);
        uint256 count = 1;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ',') count++;
        }
        address[] memory result = new address[](count);
        uint256 start = 0;
        uint256 idx = 0;
        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ',') {
                result[idx] = _parseAddrFromBytes(b, start, i);
                start = i + 1;
                idx++;
            }
        }
        return result;
    }

    function _parseAddrFromBytes(bytes memory b, uint256 start, uint256 end) internal pure returns (address) {
        uint256 len = end - start;
        require(len == 42 && b[start] == '0' && b[start+1] == 'x', "invalid address format");
        uint160 addrUint = 0;
        for (uint256 i = 0; i < 20; i++) {
            uint8 hi = _hex(uint8(b[start + 2 + i*2]));
            uint8 lo = _hex(uint8(b[start + 3 + i*2]));
            uint8 byteVal = (hi << 4) + lo;
            addrUint = (addrUint << 8) | byteVal;
        }
        return address(addrUint);
    }

    function _hex(uint8 c) internal pure returns (uint8) {
        if (c >= 48 && c <= 57) return c - 48;
        if (c >= 97 && c <= 102) return c - 87;
        if (c >= 65 && c <= 70) return c - 55;
        revert("invalid hex");
    }
}
