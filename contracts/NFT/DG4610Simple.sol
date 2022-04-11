// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../utils/MinterGuard.sol";
import "../interfaces/IDG4610.sol";
import "../interfaces/IDG721BatchReceiver.sol";
import "./ERC4610.sol";

/**
 * @dev An DG4610Simple token for Godland.
 *      Besides the burn and mint function, we make a customisation that implement a 'batch'
 *      token transfer function in consideration of reducing gas costing in game.
 *      The batch function is mainly refrence IERC1155.safeBatchTransferFrom, and also do the
 *      acceptance checks at the end of the transfer.
 */
contract DG4610Simple is MinterGuard, ERC4610, IDG4610 {
    using Strings for uint256;
    using Address for address;

    uint256 public tokenIdCounter;

    string private _uri;

    /**
     * @dev Constructor.
     * @param name_ The name of contract.
     * @param symbol_ The symbol of contract.
     */
    constructor(string memory name_, string memory symbol_) ERC4610(name_, symbol_) {}

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
        uint256[] memory ids,
        bytes memory data
    ) external override {
        for (uint256 index = 0; index < ids.length; ++index) transferFrom(from, to, ids[index]);
        _checkOnERC721BatchReceived(from, to, ids, data);
    }

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
    ) external override {
        for (uint256 index = 0; index < ids.length; ++index) {
            uint256 tokenId = ids[index];
            address delegator = delegatorOf(tokenId);
            transferFrom(from, to, tokenId);
            if (reserved) _setDelegator(delegator, tokenId);
        }
        _checkOnERC721BatchReceived(from, to, ids, data);
    }

    /**
     * @dev Mint funtion, only minter role can be callthis function
     * @param account The account will recive the token.
     */
    function mint(address account) external override onlyMinter returns (uint256 tokenIdStart) {
        return _mint(account);
    }

    function _mint(address account) internal returns (uint256 tokenIdStart) {
        tokenIdStart = tokenIdCounter;
        _safeMint(account, tokenIdStart);
        tokenIdCounter = tokenIdStart + 1;
    }

    /**
     * @dev A batch version of mint funtion
     * @param account The account will recive the token.
     * @param amount The count of token that will be minted.
     */
    function mintBatch(address account, uint256 amount) external override onlyMinter returns (uint256 tokenIdStart) {
        return _mintBatch(account, amount);
    }

    function _mintBatch(address account, uint256 amount) internal returns (uint256 tokenIdStart) {
        tokenIdStart = tokenIdCounter;
        for (uint256 offset = 0; offset < amount; ++offset) _safeMint(account, tokenIdStart + offset);
        tokenIdCounter = tokenIdStart + amount;
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
        require(ERC4610.ownerOf(tokenId) == account, "not token owner");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Batch version of burnFrom function
     */
    function burnFromBatch(address account, uint256[] calldata tokenIds) external override {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            require(ERC4610.ownerOf(tokenIds[index]) == account, "not token owner");
            require(_isApprovedOrOwner(_msgSender(), tokenIds[index]), "ERC721Burnable: caller is not owner nor approved");
            _burn(tokenIds[index]);
        }
    }

    /**
     *  @dev make a batch received check
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
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
