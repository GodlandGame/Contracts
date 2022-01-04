// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/MinterGuard.sol";
import "../interfaces/IDG721.sol";
import "../interfaces/IDG721BatchReceiver.sol";

/**
 * @dev An ERC721 token for Godland.
 *      Besides the burn and mint function, we make a customisation that implement a 'batch'
 *      token transfer function in consideration of reducing gas costing in game.
 *      The batch function is mainly refrence IERC1155.safeBatchTransferFrom, and also do the
 *      acceptance checks at the end of the transfer.
 */
contract DG721 is MinterGuard, ERC721, IDG721 {
    using Strings for uint256;
    using Address for address;

    uint256 public tokenIdCounter;
    string private _uri;

    /**
     * @dev Constructor.
     * @param name_ The name of contract.
     * @param symbol_ The symbol of contract.
     * @param uri_ The metadata url.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC721(name_, symbol_) {
        _uri = uri_;
    }

    function setUri(string calldata uri) external onlyOwner {
        _uri = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_uri, tokenId.toString(), ".json"));
    }

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
        uint256[] calldata ids,
        bytes calldata data
    ) external override {
        bool isApprovedAll = msg.sender == from ? true : isApprovedForAll(from, msg.sender);
        for (uint256 index = 0; index < ids.length; ++index) {
            uint256 tokenId = ids[index];
            require(from == ERC721.ownerOf(tokenId), "DG721BatchTransfer: caller is not owner");
            require(isApprovedAll || getApproved(tokenId) == msg.sender, "DG721BatchTransfer: caller is not approved");
            _transfer(from, to, tokenId);
        }
        _checkOnERC721BatchReceived(from, to, ids, data);
    }

    /**
     * @dev A batch version of mint funtion
     * @param account The account will recive the token.
     * @param amount The count of token that will be minted.
     */
    function mint(address account, uint256 amount) external override onlyMinter returns (uint256 tokenIdStart) {
        uint256 tokenIdCounter_ = tokenIdCounter;
        tokenIdStart = tokenIdCounter_;
        while (amount > 0) {
            _mint(account, tokenIdCounter_++);
            --amount;
        }
        tokenIdCounter = tokenIdCounter_;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Batch version of burn function
     */
    function burnBatch(uint256[] calldata tokenIds) external override {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            require(_isApprovedOrOwner(_msgSender(), tokenIds[index]), "ERC721Burnable: caller is not owner nor approved");
            _burn(tokenIds[index]);
        }
    }

    /**
     * @dev Burns `tokenId` form a specified account. See {ERC721-_burn}.
     * This function will ensure it burn token from a specified account.
     */
    function burnFrom(address account, uint256 tokenId) external override {
        require(ERC721.ownerOf(tokenId) == account, "not token owner");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Batch version of burnFrom function
     */
    function burnFromBatch(address account, uint256[] calldata tokenIds) external override {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            require(ERC721.ownerOf(tokenIds[index]) == account, "not token owner");
            require(_isApprovedOrOwner(_msgSender(), tokenIds[index]), "ERC721Burnable: caller is not owner nor approved");
            _burn(tokenIds[index]);
        }
    }

    /**
     *  @dev make a batch recived check
     */
    function _checkOnERC721BatchReceived(
        address from,
        address to,
        uint256[] memory tokenIds,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IDG721BatchReceiver(to).onERC721BatchReceived(msg.sender, from, tokenIds, _data) returns (bytes4 retval) {
                return retval == IDG721BatchReceiver(to).onERC721BatchReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("DG721: transfer to non DG721BatchReceiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
