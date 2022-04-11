// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../utils/SignerValidator.sol"; 
import "../interfaces/IERC1155Minter.sol";
import "../interfaces/IDG20.sol";
/**
 * @dev A reward deliver for Godland.
 *      It uses a signed signature to verify the given data, 
*       mint or transfer the token(s) to the caller
 */
contract RewardDeliver is Ownable, Pausable, SignerValidator { 
    using SafeERC20 for IERC20;

    // emit when someone collect his rewards
    event CollectRewards(address indexed account, uint256 mainnetAmount, uint256 agMintAmount, address[] erc20Contracts, uint256[] erc20TransferAmounts, uint256[] gadgetIds, uint256[] gadgetAmounts);
    // emit when owner add rewards to this contract
    event Injected(address indexed operator, uint256 mainnetAmount, address[] erc20Contracts, uint256[] erc20Amounts);

    IERC1155Minter public immutable godGadget;
    IDG20 public immutable ag;

    // account => nonce
    mapping(address => uint256) nonces;

    constructor(
        address signer_,
        address ag_,
        address godGadget_
    ) SignerValidator(signer_) {
        godGadget = IERC1155Minter(godGadget_);
        ag = IDG20(ag_);
        _pause();
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    
    /**
     * @dev Collect rewards thought a remote signature
     * @param mainnetAmount The BNB(or ETH) to be transfered.
     * @param agMintAmount The Ancient gold should be minted.
     * @param erc20Contracts The ERC20 token addresses.
     * @param erc20TransferAmounts The amount of each ERC20 token to be transfered.
     * @param gadgetIds The GodGadget to be minted.
     * @param gadgetAmounts The amount of each GodGadget to be minted.
     */
    function collectRewards(
        uint256 mainnetAmount,
        uint256 agMintAmount,
        address[] calldata erc20Contracts,
        uint256[] calldata erc20TransferAmounts,
        uint256[] calldata gadgetIds,
        uint256[] calldata gadgetAmounts,
        bytes calldata remoteSignature
    ) external whenNotPaused {
        // build and hash the structure
        bytes32 structHash = keccak256(abi.encode(address(this), msg.sender, mainnetAmount, agMintAmount, erc20Contracts, erc20TransferAmounts, gadgetIds, gadgetAmounts, _updateWithdrawalNonce(msg.sender)));
        // valid signature
        _validSignature(structHash, remoteSignature);
        // mint or transfer rewards
        if (mainnetAmount > 0) payable(msg.sender).transfer(mainnetAmount);
        if (agMintAmount > 0) ag.mint(msg.sender, agMintAmount);
        if (erc20Contracts.length > 0) {
            for (uint256 index = 0; index < erc20Contracts.length; ++index) IERC20(erc20Contracts[index]).safeTransfer(msg.sender, erc20TransferAmounts[index]);
        }
        if (gadgetIds.length > 0) godGadget.mintBatch(msg.sender, gadgetIds, gadgetAmounts, "");
        emit CollectRewards(msg.sender, mainnetAmount, agMintAmount, erc20Contracts, erc20TransferAmounts, gadgetIds, gadgetAmounts);
    }

    /**
     * @dev Transfer rewards to the contract for claiming 
     * @param erc20Contracts The ERC20 token addresses.
     * @param erc20Amounts The amount of each ERC20 token to be transfered. 
     */
    function inject(address[] calldata erc20Contracts, uint256[] calldata erc20Amounts) external payable onlyOwner {
        for (uint256 index = 0; index < erc20Contracts.length; ++index) {
            IERC20(erc20Contracts[index]).safeTransferFrom(msg.sender, address(this), erc20Amounts[index]);
        }
        emit Injected(msg.sender, msg.value, erc20Contracts, erc20Amounts);
    }

    /**
     * @dev Reclaim the remaining rewards to some one
     * @param to The reciver. 
     * @param erc20Contracts The ERC20 token addresses. 
     */
    function transferTo(address to, address[] calldata erc20Contracts) external whenPaused onlyOwner {
        for (uint256 index = 0; index < erc20Contracts.length; ++index) {
            IERC20 iERC20 = IERC20(erc20Contracts[index]);
            iERC20.safeTransfer(to, iERC20.balanceOf(address(this)));
        }
        if (address(this).balance > 0) payable(to).transfer(address(this).balance);
    } 
    
    
    /**
     * @dev Simple change withdraw nonce 
     */
    function _updateWithdrawalNonce(address account) private returns (uint256) {
        uint256 nonce = nonces[account];
        nonces[account] = nonce + 1;
        return nonce;
    }
}
