// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@confluxfans/contracts/InternalContracts/InternalContractsHandler.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev A batch token dropper for cryptocurrency, ERC20, ERC721 and ERC1155
 */
contract Dropship is InternalContractsHandler, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Send the cryptocurrency to accounts which is corresponding to its amount.
     * @param accounts The accounts to recive the cryptocurrency.
     * @param amounts The amount of the cryptocurrency being transfered.
     */
    function bombardment(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external payable {
        require(accounts.length == amounts.length, "accounts != amounts");
        uint256 sum;
        for (uint256 index = 0; index < accounts.length; ++index) {
            uint256 amount = amounts[index];
            payable(accounts[index]).transfer(amount);
            sum += amount;
        }
        // Sender can retrive rest cryptocurrency if the sum of amount is lesser than msg.value
        if (msg.value > sum) payable(msg.sender).transfer(msg.value - sum);
    }

    /**
     * @dev Send the ERC20 Token to the accounts which is corresponding to its amount.
     *      Sender should allow contract to spend his token.
     * @param tokenAddress The contract address of the ERC20 token.
     * @param accounts The accounts to recive the tokens.
     * @param amounts The amount of the token being transfered.
     */
    function erc20bombardment(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(accounts.length == amounts.length, "accounts != amounts");
        IERC20 token = IERC20(tokenAddress);
        for (uint256 index = 0; index < accounts.length; ++index) {
            uint256 amount = amounts[index];
            if (amounts[index] > 0)
                token.safeTransferFrom(msg.sender, accounts[index], amount);
        }
    }

    /**
     * @dev Send the ERC20 Token to the accounts which is corresponding to its amount.
     *      Sender should allow contract to spend his token.
     * @param tokenAddress The contract address of the ERC20 token.
     * @param accounts The accounts to recive the tokens.
     * @param amounts The amount of the token being transfered.
     * @param totalAmount The total amount of the token being transfered, 
         should be calculate offchain to save gas.
     */
    function erc20bombardmentV2(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 totalAmount
    ) external nonReentrant {
        require(accounts.length == amounts.length, "accounts != amounts");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), totalAmount);
        for (uint256 index = 0; index < accounts.length; ++index) {
            uint256 amount = amounts[index];
            token.safeTransfer(accounts[index], amount);
            totalAmount -= amount;
        }
        if (totalAmount > 0) token.safeTransfer(msg.sender, totalAmount);
    }

    /**
     * @dev Send the ERC721 Token to the accounts which is corresponding to its amount.
     *      Sender should allow contract to spend his token.
     * @param tokenAddress The contract address of the ERC721 token.
     * @param accounts The accounts to recive the tokens.
     * @param ids The id of the token being transfered.
     */
    function erc721bombardment(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata ids
    ) external nonReentrant {
        require(accounts.length == ids.length, "accounts != ids");
        IERC721 token = IERC721(tokenAddress);
        for (uint256 index = 0; index < accounts.length; ++index) {
            token.safeTransferFrom(msg.sender, accounts[index], ids[index]);
        }
    }

    /**
     * @dev Send the ERC1155 Token to the accounts which is corresponding to its amount.
     *      Sender should allow contract to spend his token.
     * @param tokenAddress The contract address of the ERC1155 token.
     * @param accounts The accounts to recive the tokens.
     * @param ids The id of the token being transfered.
     * @param amounts The amount of the token being transfered.
     */
    function erc1155bombardment(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external nonReentrant {
        require(accounts.length == ids.length, "accounts != ids");
        require(accounts.length == amounts.length, "accounts != amounts");
        IERC1155 token = IERC1155(tokenAddress);
        for (uint256 index = 0; index < accounts.length; ++index) {
            token.safeTransferFrom(
                msg.sender,
                accounts[index],
                ids[index],
                amounts[index],
                ""
            );
        }
    }
}
