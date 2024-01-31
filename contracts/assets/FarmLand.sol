// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract FarmLand is ERC721, Ownable, ERC2981 {

    string baseURI = "https://mint.pixels.online/contracts/0x5c1a0cc6dadf4d0fb31425461df35ba80fcbc110/"; 
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
        _setTokenRoyalty(tokenId, msg.sender, 500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}