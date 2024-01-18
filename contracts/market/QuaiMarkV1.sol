// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../library/TransferHelper.sol";
import "../interface/IWETH.sol";

contract QuaiMarkV1 is AccessControl, ReentrancyGuard {

    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); 
    uint256 public transactionFee;
    uint256 public totalFee;
    address public WETH;
    uint256 MAX_END_TIME = 2592000;

    mapping(address => mapping(uint256 => Listing)) private listings;
    mapping(address => mapping(address => mapping(uint256 => Offering))) private offerings;
   
    struct Listing {
        address seller;
        uint256 price; 
        uint256 endtime;
        bool status;
    }

    struct Offering {
        uint256 price;
        uint256 endtime;
        bool status;
    }

    struct Bag {
        address nftAddress;
        uint256 tokenId;
    }

    modifier notListed(
        address nftAddress,
        address spender,
        uint256 tokenId
    ) {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.endtime < block.timestamp || listing.seller != spender || !listing.status, "QUAIMARK: NOT_LISTED_WRONG");
        _;
    }

    modifier isOwner(
        address nftAddress,
        address spender,
        uint256 tokenId
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        require(spender == owner, "QUAIMARK: IS_OWNER_WRONG");
        _;
    }

    modifier verifyPrice(uint256 price) {
        require(price > 0, "QUAIMARK: PRICE_WRONG");
        _;
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

    event ListItem(
        address user,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 endTime,
        uint256 option,
        uint256 blockTime
    );

    event UpdateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 blockTime
    );

    event SetTransactionFee(
        uint256 transactionFee,
        uint256 blockTime
    );

    function setTransactionFee(uint256 _transactionFee) public onlyRole(ADMIN_ROLE) {
        transactionFee = _transactionFee;
        emit SetTransactionFee(_transactionFee, block.timestamp);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint amount = totalFee;
        totalFee = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
        emit Withdraw(amount, block.timestamp);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns(Listing memory) {
        return listings[nftAddress][tokenId];
    }

    function getOffering(address user, address nftAddress, uint256 tokenId) external view returns(Offering memory) {
        return offerings[user][nftAddress][tokenId];
    }

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 endtime
    ) 
        external 
        isOwner(nftAddress, msg.sender, tokenId)
        verifyPrice(price)
    {   
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.endtime < block.timestamp || listing.seller != msg.sender || !listing.status, "QUAIMARK: NOT_LISTED_WRONG");
        require(endtime < (block.timestamp + MAX_END_TIME) && endtime > block.timestamp,"QUAIMARK: END_TIME_WRONG");
        
        listings[nftAddress][tokenId] = Listing(msg.sender, price, endtime, true);
        emit ListItem(
            msg.sender,
            nftAddress,
            tokenId,
            price,
            endtime,
            1,
            block.timestamp
        );
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) 
        external 
        isOwner(nftAddress, msg.sender, tokenId)
        verifyPrice(newPrice)
    {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.endtime > block.timestamp && listing.seller == msg.sender && listing.status, "QUAIMARK: IS_LISTED_WRONG");
        listings[nftAddress][tokenId].price = newPrice;
        emit UpdateListing(nftAddress, tokenId, newPrice, block.timestamp);
    }

    function bag(Bag[] memory _bag) external payable {
        for(uint256 i = 0; i < _bag.length; i++){
            matchTransaction(_bag[i].nftAddress , _bag[i].tokenId);
        }
    }

    function matchTransaction(
        address nftAddress,
        uint256 tokenId
    ) 
        public 
        payable 
        nonReentrant
    {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.endtime > block.timestamp && listedItem.status, "QUAIMARK: IS_LISTED_WRONG");
        require(IERC721(nftAddress).ownerOf(tokenId) == listedItem.seller,"QUAIMARK: seller is not owner of this item now");
        if (msg.value > listedItem.price) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(listedItem.price));
        uint256 fee = transactionFee.mul(listedItem.price).div(1000);
        totalFee += fee;
        uint256 payToSellerAmount = listedItem.price.sub(fee);
        TransferHelper.safeTransferETH(listedItem.seller, payToSellerAmount);
        TransferHelper.safeTransferFromERC721(nftAddress, listedItem.seller, _msgSender(), tokenId);
        emit MatchTransaction(tokenId, nftAddress, listedItem.price, WETH, listedItem.seller, msg.sender, 1, listedItem.endtime);
    }

    function matchOffer(
        address nftAddress,
        uint256 tokenId,
        address buyer
    ) external  {
        Offering memory offerItem = offerings[buyer][nftAddress][tokenId];
        require(offerItem.endtime > block.timestamp && offerItem.status,"QUAIMARK: OFFER_WRONG");
        TransferHelper.safeTransferFrom(WETH, buyer, address(this), offerItem.price);
        IWETH(WETH).withdraw(offerItem.price);
        uint256 fee = transactionFee.mul(offerItem.price).div(1000);
        uint256 payToSellerAmount = offerItem.price.sub(fee);
        TransferHelper.safeTransferETH(_msgSender(), payToSellerAmount);
        totalFee += fee;
        TransferHelper.safeTransferFromERC721(nftAddress, _msgSender(), buyer, tokenId);
        emit MatchTransaction(tokenId, nftAddress, offerItem.price, WETH, _msgSender(), buyer, 2, offerItem.endtime);
    }

    function offer(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 endtime
    ) 
        external 
        verifyPrice(price)
    {
        require(
            IERC20(WETH).allowance(_msgSender(), address(this)) >= price,
            "QuaiMark: buyer doesn't approve marketplace to spend payment amount"
        );
        require(endtime < (block.timestamp + MAX_END_TIME) && endtime > block.timestamp,"QUAIMARK: END_TIME_WRONG");
        offerings[msg.sender][nftAddress][tokenId] = Offering(price, endtime, true);
        emit ListItem(msg.sender, nftAddress, tokenId, price, endtime, 2, block.timestamp);
    }

    function cancelMessage(
        address nftAddress,
        uint256 tokenId,
        uint256 option
    ) 
        external 
    {
        require(option == 1 || option == 2, "QUAIMARK: CANCEL_MESSAGE_WRONG");
        if(option == 1){
            Listing memory listingInfor = listings[nftAddress][tokenId];
            require(listingInfor.endtime > block.timestamp && listingInfor.seller == msg.sender && listingInfor.status, "QUAIMARK: IS_LISTED_WRONG");
            listingInfor.status = false;
            emit Cancel(tokenId, nftAddress, WETH, 1, listingInfor.endtime, block.timestamp);
        }
        if(option == 2){
            Offering memory offeringInfor = offerings[msg.sender][nftAddress][tokenId];
            require(offeringInfor.endtime > block.timestamp && offeringInfor.price > 0 && offeringInfor.status, "QUAIMARK: CANCEL_OFFER_WRONG");
            offeringInfor.status = false;
            emit Cancel(tokenId, nftAddress, WETH, 2, offeringInfor.endtime, block.timestamp);
        }
    }
    
}