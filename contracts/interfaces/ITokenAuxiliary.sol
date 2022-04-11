// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenAuxiliary {
    /**
     * @dev Get account's runes
     * @param account The account be check.
     */
    function userRunes(address account) external view returns (uint256[] memory amounts);

    /**
     * @dev Consume account's runes
     * @param account The account to be consumed.
     * @param runeIdx The rune indexes to be consumed.
     * @param amounts The amounts of each index to be consumed.
     */
    function consumeRune(
        address account,
        uint256[] calldata runeIdx,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Add account's runes
     * @param account The account to be added.
     * @param runeIdx The rune indexes to be added.
     * @param amounts The amounts of each index to be added.
     */
    function addRune(
        address account,
        uint256[] calldata runeIdx,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Get account's DGT amounts
     * @param account The account be check.
     */
    function userDGT(address account) external view returns (uint256 amount);

    /**
     * @dev Consume account's DGT
     * @param account The account to be consumed.
     * @param amount The amount to be consumed.
     */
    function consumeDGT(address account, uint256 amount) external;

    /**
     * @dev Add account's DGT amounts
     * @param account The account be added.
     * @param amount The amount to be added.
     */
    function addDGT(address account, uint256 amount) external;
}
