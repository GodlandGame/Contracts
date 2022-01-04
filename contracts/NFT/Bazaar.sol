// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../utils/OperatorGuard.sol";

/**
 * @dev A totally decentralized secondary market contract for Godland.
 * Anyone can sell his GodGadget and other allowed NFT thought this contract
 */
contract Bazaar is OperatorGuard, ERC1155Receiver, IERC721Receiver, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    event OrderCreated(uint256 indexed orderId, address indexed creator, address tokenSource, uint256 unitPrice, uint256 tokenId, address payToken, uint256 amount);
    event OrderUpdated(uint256 indexed orderId, uint256 unitPrice);
    event OrderCancelled(uint256 indexed orderId, uint256 amountRest);
    event Purchased(uint256 indexed orderId, address indexed buyer, uint256 uintPrice, uint256 amount);

    // we have 5% percent fee
    uint256 public constant feePercentage = 5;
    uint256 public constant fullPercentage = 100;
    uint256 private constant maxUint96 = (1 << 97) - 1;
    // for mainnet currency, such as ETH, BNB etc, we hard coded its contract address as 0x0
    address public constant mainnetTokenAddress = address(0x0);

    struct Order {
        address creator; // seller
        uint96 unitPrice; // fixed price
        address tokenSource; // from contract
        uint96 tokenId; // token that to be sale
        uint96 rest; // rest amount
        address payToken; // pay token
    }

    // order id => order
    mapping(uint256 => Order) private _orders;
    uint256 private _orderCounter;

    address public feeReciver;

    EnumerableSet.AddressSet private _supportedToken;
    EnumerableSet.UintSet private _orderIds;

    /**
     * @dev Constructor.
     * @param feeReciver_ The fee reciver
     */
    constructor(address feeReciver_) {
        feeReciver = feeReciver_;
        // support mainnet currency at first
        _supportedToken.add(mainnetTokenAddress);
    }

    function setFeeReciver(address feeReciver_) external onlyOwner {
        feeReciver = feeReciver_;
    }

    /**
     * @dev Add a ERC20 token as payable token.
     * @param token The fee token
     */
    function addSupportedToken(address token) external onlyOwner {
        require(_supportedToken.add(token), "token already exists");
    }

    /**
     * @dev Remove a ERC20 token as payable token.
     * @param token The fee token
     */
    function removeSupportedToken(address token) external onlyOwner {
        require(_supportedToken.remove(token), "token not exists");
    }

    /**
     * @dev List all supported token
     */
    function supportedTokens() external view returns (address[] memory supportedTokens_) {
        uint256 count = _supportedToken.length();
        supportedTokens_ = new address[](count);
        for (uint256 index = 0; index < count; ++index) supportedTokens_[index] = _supportedToken.at(index);
    }

    /**
     * @dev Get opened order counts
     */
    function orderCount() external view returns (uint256 count) {
        count = _orderIds.length();
    }

    /**
     * @dev Get order id by index
     */
    function orderIdByIndex(uint256 index) external view returns (uint256 orderId) {
        orderId = _orderIds.at(index);
    }

    /**
     * @dev Get order details
     */
    function orderById(uint256 orderId)
        external
        view
        returns (
            address creator,
            uint256 unitPrice,
            address tokenSource,
            uint256 tokenId,
            uint256 rest,
            address payToken
        )
    {
        creator = _orders[orderId].creator;
        unitPrice = _orders[orderId].unitPrice;
        tokenSource = _orders[orderId].tokenSource;
        tokenId = _orders[orderId].tokenId;
        rest = _orders[orderId].rest;
        payToken = _orders[orderId].payToken;
    }

    /**
     * @dev Create an order, it should only call from reciver handler
     */
    function _creatrOrder(
        address creator,
        uint256 tokenId,
        address tokenSource,
        uint256 amount,
        bytes calldata data
    ) private whenNotPaused {
        // decode data as pay token and fixed price
        (address payToken, uint96 unitPrice) = abi.decode(data, (address, uint96));
        _validPayToken(payToken);
        
        uint256 orderCounter = _orderCounter;
        _orderIds.add(orderCounter);
        _orders[orderCounter].creator = creator;
        _orders[orderCounter].unitPrice = unitPrice;
        _orders[orderCounter].tokenSource = tokenSource;
        _orders[orderCounter].tokenId = uint96(tokenId);
        _orders[orderCounter].rest = uint96(amount);
        _orders[orderCounter].payToken = payToken;
        emit OrderCreated(orderCounter, creator, tokenSource, unitPrice, tokenId, payToken, amount);
        _orderCounter = orderCounter + 1;
    }

    /**
     * @dev Update the price of an order.
     * @param orderId The order id.
     * @param unitPrice The fixed price for each entry.
     */
    function updateOrder(uint256 orderId, uint96 unitPrice) external whenNotPaused {
        require(_orders[orderId].creator == msg.sender, "require order creator");
        _orders[orderId].unitPrice = unitPrice;
        emit OrderUpdated(orderId, unitPrice);
    }

    /**
     * @dev Cancel an order, then reclaim the rest tokens.
     * @param orderId The order id.
     */
    function cancelOrder(uint256 orderId) external whenNotPaused {
        require(_orders[orderId].creator == msg.sender, "require order creator");
        uint256 rest = _orders[orderId].rest;
        address tokenSource = _orders[orderId].tokenSource;
        uint256 tokenId = _orders[orderId].tokenId;
        delete _orders[orderId];
        _orderIds.remove(orderId);
        _transferNFTToken(tokenSource, msg.sender, tokenId, rest);
        emit OrderCancelled(orderId, rest);
    }

    function _validPayToken(address payToken) private view {
        require(_supportedToken.contains(payToken), "pay token not allowed");
    }

    /**
     * @dev Cancel an order, then reclaim the rest tokens.
     * @param orderId The order id.
     */
    function purchase(uint256 orderId, uint256 quantity) external payable whenNotPaused nonContractCaller {
        address buyer = msg.sender;
        Order storage order = _orders[orderId];
        (address creator, uint256 unitPrice, address payToken, uint256 rest) = (order.creator, order.unitPrice, order.payToken, order.rest);
        uint256 shouldPayed = quantity * unitPrice;
        _purchase(orderId, unitPrice, buyer, rest, quantity);
        _transferInToken(payToken, shouldPayed, buyer, creator);
    }

    /**
     * @dev Inner implementation of purchase
     */
    function _purchase(
        uint256 orderId,
        uint256 unitPrice,
        address buyer,
        uint256 rest,
        uint256 quantity
    ) private {
        require(rest >= quantity, "not enought stock");
        unchecked {
            rest -= quantity;
        }
        address tokenSource = _orders[orderId].tokenSource;
        uint256 tokenId = _orders[orderId].tokenId;
        if (rest > 0) _orders[orderId].rest = uint96(rest);
        else {
            delete _orders[orderId];
            _orderIds.remove(orderId);
        }
        _transferNFTToken(tokenSource, buyer, tokenId, quantity);
        emit Purchased(orderId, buyer, unitPrice, quantity);
    }

    /**
     * @dev Process of transfer in token
     */
    function _transferInToken(
        address contractAddress,
        uint256 amount,
        address spender,
        address reciver
    ) private {
        uint256 fee = (amount * feePercentage) / fullPercentage;
        uint256 amountToReciver = amount - fee;
        if (contractAddress == mainnetTokenAddress) {
            if (msg.value != amount) {
                if (msg.value > amount) payable(spender).transfer(msg.value - amount);
                else revert("not enought payed");
            }
            payable(reciver).transfer(amountToReciver);
            if (fee > 0) payable(feeReciver).transfer(fee);
        } else {
            IERC20 erc20 = IERC20(contractAddress);
            erc20.safeTransferFrom(spender, reciver, amountToReciver);
            if (fee > 0) erc20.safeTransferFrom(spender, feeReciver, fee);
            if (msg.value > 0) payable(spender).transfer(msg.value);
        }
    }

    /**
     * @dev Transfer nft to user's account
     * it will decide whether an IERC1155 contract or IERC721 contract
     */
    function _transferNFTToken(
        address contractAddress,
        address to,
        uint256 tokenId,
        uint256 amount
    ) private {
        IERC165 erc165 = IERC165(contractAddress);
        if (erc165.supportsInterface(type(IERC1155).interfaceId)) IERC1155(contractAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
        else {
            require(amount == 1, "amount should == 1");
            IERC721(contractAddress).safeTransferFrom(address(this), to, tokenId);
        }
    }

    function composeData(address payToken, uint96 unitPrice) external pure returns (bytes memory) {
        return abi.encode(payToken, unitPrice);
    }

    function decomposeData(bytes calldata data) external pure returns (address payToken, uint96 unitPrice) {
        (payToken, unitPrice) = abi.decode(data, (address, uint96));
    }

    /**
     * @dev ERC721 reciver handler
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override onlyOperator returns (bytes4) {
        require(operator == from && tx.origin == from, "should send from owner only");
        require(tokenId <= maxUint96, "token id exceeds");
        _creatrOrder(from, tokenId, msg.sender, 1, data);
        return this.onERC721Received.selector;
    }

    /**
     * @dev ERC1155 reciver handler
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external override onlyOperator returns (bytes4) {
        require(operator == from && tx.origin == from, "should send from owner only");
        require(tokenId <= maxUint96, "token id exceeds");
        require(amount <= maxUint96, "transfer count exceeds");
        _creatrOrder(from, tokenId, msg.sender, amount, data);
        return this.onERC1155Received.selector;
    }

    /**
     * @dev ERC1155 batch reciver handler
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("not supported");
    }

    modifier nonContractCaller() {
        require(tx.origin == msg.sender, "cannot call from contract");
        _;
    }
}
