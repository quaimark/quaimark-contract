// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TransferHelper.sol";

contract OverMint is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable; 
    using SafeMathUpgradeable for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); 
    mapping(address => bool) public assetToken;
    mapping(bytes => bool) public usedSignatures;
    uint256 public transactionFee;
    uint256 public totalFee;
    function initialize() initializer public {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    } 
    event AddToken(
        address asset,
        uint256 timeStamp
    );
    event RemoveToken(
        address asset,
        uint256 timeStamp
    );
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

    function addToken(address asset) external onlyRole(ADMIN_ROLE){
        assetToken[asset] = true;
        emit AddToken(asset,block.timestamp);
    }

    function removeToken(address asset) external onlyRole(ADMIN_ROLE) {
        require(assetToken[asset], "Asset not found");
        assetToken[asset] = false;
        emit RemoveToken(asset, block.timestamp);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint amount = totalFee;
        totalFee = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
        emit Withdraw(amount, block.timestamp);
    }

    struct Bag {
        address[3] addresses;
        uint256[4] values;
        bytes signature;
    }

    function bag(Bag[] memory _bag) external payable returns (bool){
        for(uint256 i = 0; i < _bag.length; i++){
            matchTransaction(_bag[i].addresses , _bag[i].values, _bag[i].signature);
        }
        return true;
    }

    function matchTransaction(
        address[3] memory addresses,
        uint256[4] memory values,
        bytes memory signature
    ) public payable returns (bool){
        // addresses: address[0]: seller, address[1]: nft, address[2]: paymentMethod
        // values: value[0]: tokenId, value[1]: price, value[2]: satnonce, value[3]: period
        // option 1: matchTransaction , option 2 : matchOffer
        require(assetToken[addresses[1]], "OverMint: invalid asset.");
        require(!usedSignatures[signature], "OverMint: signature used.");
        require(values[2].add(values[3]) > block.timestamp && values[2] < block.timestamp, "OverMint: item sold out");
        require(values[1] > 0, "OverMint: invalid price");
        usedSignatures[signature] = true;
        bytes32 criteriaMessageHash = getMessageHash(addresses[1],values[0],addresses[2],values[1],values[2],values[3],1);
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(criteriaMessageHash);
        require(ECDSAUpgradeable.recover(ethSignedMessageHash, signature) == addresses[0],"OverMint: invalid seller signature");
        require(IERC721Upgradeable(addresses[1]).ownerOf(values[0]) == addresses[0],"OverMint: seller is not owner of this item now");
        require(msg.value >= values[1], "OverMint: buyer doesn't have enough token to buy this item");
        if (msg.value > values[1]) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(values[1]));
        uint256 fee = transactionFee.mul(values[1]).div(1000);
        uint256 payToSellerAmount = values[1].sub(fee);
        totalFee += fee;
        TransferHelper.safeTransferETH(addresses[0], payToSellerAmount);
        IERC721Upgradeable(addresses[1]).safeTransferFrom(addresses[0], _msgSender(), values[0]);
        emitMatchTransaction(addresses, values);
        return true;
    }

    function cancelMessage(
        address[3] memory addresses,
        uint256[5] memory values,
        bytes memory signature
    ) external returns (bool) {
        // addresses: address[0]: seller or buyer, address[1]: nft, address[2]: paymentMethod
        // values: value[0]: tokenId, value[1]: price, value[2]: satnonce, value[3]: period, value[4]: option
        // require(paymentToken[addresses[1]][addresses[2]] == true,"OverMint: invalid payment method");
        bytes32 criteriaMessageHash = getMessageHash(addresses[1],values[0],addresses[2],values[1],values[2],values[3],values[4]);
        bytes32 ethSignedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(criteriaMessageHash);
        require(ECDSAUpgradeable.recover(ethSignedMessageHash, signature) == msg.sender,"OverMint: invalid seller signature");
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
}