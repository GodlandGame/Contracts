// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4610.sol";

interface IDG4610 is IERC4610 {
    /**
     * @dev A batch version of transfer tokens to another account, also whill check acceptance at the end of the transfer
     * @param from The account will send the token.
     * @param to The token reciver.
     * @param ids The token ids that will be sent.
     * @param data The additional data for transfer handler.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) external;

    /**
     * @dev A batch version of transfer tokens to another account, also whill check acceptance at the end of the transfer
     * @param from The account will send the token.
     * @param to The token reciver.
     * @param ids The token ids that will be sent.
     * @param data The additional data for transfer handler.
     * @param reserved To clear the reservation or not
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool reserved
    ) external;

    /**
     * @dev Mint funtion, only minter role can be callthis function
     * @param account The account will recive the token.
     */
    function mint(address account) external returns (uint256 tokenIdStart);

    /**
     * @dev A batch version of mint funtion
     * @param account The account will recive the token.
     * @param amount The count of token that will be minted.
     */
    function mintBatch(address account, uint256 amount) external returns (uint256 tokenIdStart);

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Batch version of burn function
     */
    function burnBatch(uint256[] calldata tokenIds) external;
    
    /**
     * @dev Burns `tokenId` form a specified account. See {ERC721-_burn}.
     * This function will ensure it burn token from a specified account.
     */
    function burnFrom(address account, uint256 tokenId) external;

    /**
     * @dev Batch version of burnFrom function
     */
    function burnFromBatch(address account, uint256[] calldata tokenIds) external;
}
