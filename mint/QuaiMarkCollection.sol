// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract QuaiMarkCollection is ERC721A, ERC2981 {

    mapping(address => bool) private admin;
    
    constructor(string memory name, uint256 _royalty, string memory _url) {
        
    }
}