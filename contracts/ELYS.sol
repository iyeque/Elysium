   // SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

   contract ELYS is ERC20 {
       uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

       constructor() ERC20("Elysium", "ELYS") {
           _mint(msg.sender, MAX_SUPPLY);
       }

       // Stub for Governor compatibility (returns current balance)
       function getPriorVotes(address account, uint256) public view returns (uint256) {
           return balanceOf(account);
       }
   }