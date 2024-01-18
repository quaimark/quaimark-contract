// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../library/TransferHelper.sol";
import "../interface/IWETH.sol";

contract QuaiMark is AccessControl, ReentrancyGuard {

    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); 
    uint256 public transactionFee;
    uint256 public totalFee;
    address public WETH;
   
    mapping(bytes => bool) public usedSignatures;

    struct Bag {
        address[3] addresses;
        uint256[4] values;
        bytes signature;
    }

    constructor(address _weth){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        WETH = _weth;
    }

    receive() external payable {}

    event MatchTransaction(
        uint256 indexed tokenId,
        address contractAddress,
        uint256 price,
        address paymentToken,
        address seller,
        address buyer,
        uint256 option, 
        uint256 timeListing
    ); // option 1: matchTransaction , option 2 : matchOffer

    event Cancel(
        uint256 tokenId,
        address contractAddress,
        address paymentToken,
        uint256 option,
        uint256 saltnonce,
        uint256 timeCancel
    );
    
    event Withdraw(
        uint256 amount,
        uint256 timeStamp
    );

    function setTransactionFee(uint256 _transactionFee) public onlyRole(ADMIN_ROLE) {
        transactionFee = _transactionFee;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint amount = totalFee;
        totalFee = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
        emit Withdraw(amount, block.timestamp);
    }

    function getMessageHash(
        address _nftAddress,
        uint256 _tokenId,
        address _paymentErc20,
        uint256 _price,
        uint256 _saltNonce,
        uint256 _period,
        uint256 _option
    ) public pure returns (bytes32) {
         return
            keccak256(
                abi.encodePacked(
                    _nftAddress,
                    _tokenId,
                    _paymentErc20,
                    _price,
                    _saltNonce,
                    _period,
                    _option
                )
            );
    }

    function bag(Bag[] memory _bag) external payable {
        for(uint256 i = 0; i < _bag.length; i++){
            matchTransaction(_bag[i].addresses , _bag[i].values, _bag[i].signature);
        }
    }

    function matchTransaction(
        address[3] memory addresses,
        uint256[4] memory values,
        bytes memory signature
    ) public payable {
        // addresses: address[0]: seller, address[1]: nft, address[2]: tokenPayment
        // values: value[0]: tokenId, value[1]: price, value[2]: satnonce, value[3]: period
        // option 1: matchTransaction , option 2 : matchOffer
        require(!usedSignatures[signature], "QUAIMARK: signature used.");
        require(values[2].add(values[3]) > block.timestamp && values[2] < block.timestamp, "QUAIMARK: item sold out");
        require(values[1] > 0, "QUAIMARK: invalid price");
        usedSignatures[signature] = true;
        bytes32 criteriaMessageHash = getMessageHash(addresses[1],values[0],addresses[2],values[1],values[2],values[3],1);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(criteriaMessageHash);
        require(ECDSA.recover(ethSignedMessageHash, signature) == addresses[0],"QUAIMARK: invalid seller signature");
        require(IERC721(addresses[1]).ownerOf(values[0]) == addresses[0],"QUAIMARK: seller is not owner of this item now");
        if (msg.value > values[1]) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(values[1]));
        uint256 fee = transactionFee.mul(values[1]).div(1000);
        uint256 payToSellerAmount = values[1].sub(fee);
        totalFee += fee;
        TransferHelper.safeTransferETH(addresses[0], payToSellerAmount);
        TransferHelper.safeTransferFromERC721(addresses[1], addresses[0], _msgSender(), values[0]);
        emitMatchTransaction(addresses, values);
    }

    function matchOffer(
        address[3] calldata addresses,
        uint256[4] calldata values,
        bytes calldata signature
    ) external {
        // addresses: address[0]: buyer, address[1]: nft, address[2]: paymentMethod
        require(!usedSignatures[signature], "QUAIMARK: signature used.");
        require(values[2].add(values[3]) > block.timestamp && values[2] < block.timestamp, "QUAIMARK: item sold out");
        require(values[1] > 0, "QUAIMARK: invalid price");
        usedSignatures[signature] = true;
        bytes32 criteriaMessageHash = getMessageHash(addresses[1],values[0],addresses[2],values[1],values[2],values[3],2);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(criteriaMessageHash);
        require(ECDSA.recover(ethSignedMessageHash, signature) == addresses[0],"QUAIMARK: invalid buyer signature");
        require(IERC721(addresses[1]).ownerOf(values[0]) == _msgSender(),"QUAIMARK: seller is not owner of this item now");
        TransferHelper.safeTransferFrom(WETH, addresses[0], address(this), values[1]);
        IWETH(WETH).withdraw(values[1]);
        uint256 fee = transactionFee.mul(values[1]).div(1000);
        uint256 payToSellerAmount = values[1].sub(fee);
        TransferHelper.safeTransferETH(_msgSender(), payToSellerAmount);
        totalFee += fee;
        TransferHelper.safeTransferFromERC721(addresses[1], _msgSender(), addresses[0], values[0]);
        emitMatchOffer(addresses, values);
    }

    function cancelMessage(
        address[3] memory addresses,
        uint256[5] memory values,
        bytes memory signature
    ) external returns (bool) {
        // addresses: address[0]: seller or buyer, address[1]: nft, address[2]: tokenPayment
        // values: value[0]: tokenId, value[1]: price, value[2]: satnonce, value[3]: period, value[4]: option
        // require(paymentToken[addresses[1]][addresses[2]] == true,"QUAIMARK: invalid payment method");
        bytes32 criteriaMessageHash = getMessageHash(addresses[1],values[0],addresses[2],values[1],values[2],values[3],values[4]);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(criteriaMessageHash);
        require(ECDSA.recover(ethSignedMessageHash, signature) == msg.sender,"QUAIMARK: invalid seller signature");
        usedSignatures[signature] = true;
        emit Cancel(
            values[0],
            addresses[1],
            addresses[2],
            values[4],
            values[2],
            block.timestamp
        );
        return true;
    }

    function emitMatchTransaction(
        address[3] memory addresses,
        uint256[4] memory values
    ) internal {
        emit MatchTransaction(
            values[0],
            addresses[1],
            values[1],
            addresses[2],
            addresses[0],
            _msgSender(),
            values[3],
            values[2]
        );
    }

    function emitMatchOffer(
        address[3] calldata addresses,
        uint256[4] calldata values
    ) internal {
        emit MatchTransaction(
            values[0],
            addresses[1],
            values[1],
            addresses[2],
            _msgSender(),
            addresses[0],
            values[3],
            values[2]
        );
    }

}