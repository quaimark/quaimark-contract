// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Assets is ERC721, Ownable {

    string baseURI = "http://localhost:3000"; 
    constructor(string memory name, string memory symbol) ERC721(name, symbol)
    {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory _baseUri) public onlyOwner() {
        baseURI = _baseUri;
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}