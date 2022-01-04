// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./GodGadget.sol";
import "../interfaces/IERC1155Minter.sol";

/**
 * @dev A GodGadget minter contract for Godland.
 *      Mainly used in Godland Bounty System
 */
contract BountyMinter is Ownable, Pausable {
    event MintThoughtRemote(address indexed account, uint256 tokenId, uint256 value, uint256 withdrawal);

    IERC1155Minter public immutable forge;
    address private _remoteSigner;

    // account => tokenId => amount
    mapping(address => mapping(uint256 => uint256)) public userWithdrawal;

    
    /**
     * @dev Constructor.
     * @param forge_ The address of the GodGadget.
     * @param remoteSigner_ The server signer address.
     */
    constructor(address forge_, address remoteSigner_) {
        forge = IERC1155Minter(forge_);
        _remoteSigner = remoteSigner_;
        _pause();
    }

    function setRemoteSigner(address remoteSigner_) external onlyOwner {
        _remoteSigner = remoteSigner_;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
    
    /**
     * @dev Mint NFT thought server's signature. Use user's withdrawal as nonce
     * @param tokenId The token Id that will be minted
     * @param amount The amount that will be minted.
     * @param remoteSignature The signature from server.
     */
    function mintBySignature(
        uint256 tokenId,
        uint256 amount,
        bytes calldata remoteSignature
    ) external whenNotPaused {
        address account = msg.sender;
        uint256 nonce = _updateWithdrawalNonce(account, tokenId, amount);        
        bytes32 structHash = keccak256(abi.encode(address(this), account, tokenId, amount, nonce));
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(structHash), remoteSignature);
        require(signer == _remoteSigner, "invalid signature");
        forge.mint(account, tokenId, amount, "");
        emit MintThoughtRemote(account, tokenId, amount, nonce + amount);
    }

   
    /**
     * @dev Update user's widthdrawal(as nonce) 
     */
    function _updateWithdrawalNonce(
        address account,
        uint256 tokenId,
        uint256 amount
    ) private returns (uint256) {
        uint256 nonce = userWithdrawal[account][tokenId];
        userWithdrawal[account][tokenId] = nonce + amount;
        return nonce;
    }
}
