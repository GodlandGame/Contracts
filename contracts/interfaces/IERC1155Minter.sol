// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Minter is IERC1155 {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must be a minters.
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Batch version of mint function
     */
    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - caller should be self of approved account
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    /**
     * @dev Batch version of burn function
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}
