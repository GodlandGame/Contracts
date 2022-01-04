// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDG721BatchReceiver {
    /**
        @dev Handles the receipt of a multiple DG721 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC721BatchReceived(address,address,uint256[],bytes)"))` 
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param tokenIds An array containing ids of each token being transferred (order and length must match values array) 
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC721BatchReceived(address,address,uint256[],bytes)"))` if transfer is allowed
    */
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external returns (bytes4);
}
