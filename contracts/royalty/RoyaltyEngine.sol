pragma solidity ^0.8.9;
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract RoyaltyEngine {

    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        public
        view
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        try IERC2981(tokenAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
            recipients = new address payable[](1);
            amounts = new uint256[](1);
            recipients[0] = payable(recipient);
            amounts[0] = amount;
        }  catch { }
    }

    function getStatus(address tokenAddress, uint256 tokenId, uint256 value) 
        public 
        view
        returns (bool) 
    {
        bytes4 sector = bytes4(keccak256(bytes('royaltyInfo(uint256,uint256)')));
        (bool success, ) = tokenAddress.staticcall(abi.encodeWithSelector(sector, tokenId, value));
        return success;
    }
}