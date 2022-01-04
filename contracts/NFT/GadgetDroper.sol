// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "../interfaces/IERC1155Minter.sol";
import "../utils/SignerValidator.sol";

/**
 * @dev An Godgadget airdropper for Godland.
 * User can exchange or claim GodGadgets according to the airdrop plan.
 * Some of the might needs a signature form server.
 */
contract GadgetDroper is Ownable, SignerValidator, ERC1155Receiver {
    event AirdropUpdates(
        uint256 indexed id,
        uint256 payTokenId,
        uint256 payTokenCount,
        uint256 tokenId,
        uint256 tokenCount,
        uint256 supply,
        bool requireSigner,
        bool isClaimable
    );

    struct Airdrop {
        uint32 payTokenId; // token id to pay for the airdrop
        uint32 payTokenCount; // token count to pay for the airdrop
        uint32 tokenId; // the token to recive
        uint32 tokenCount; // the amount token to recive
        uint32 supply; // current supply
        uint32 totalSupply; // total supply
        bool requireSigner; // whether needs server sign
        bool isClaimable; // cliamble control
    }

    uint256 public airdropCount;
    mapping(uint256 => Airdrop) public airdrops;
    // airdrop id => user => claimed
    // each airdrop should be claimed only once
    mapping(uint256 => mapping(address => bool)) private _claimed;

    address public immutable godGadgetForge;

    /**
     * @dev Constructor.
     * @param remoteSigner_ The signer incase to use.
     * @param godGadgetForge_ The GodGadget contract.
     */
    constructor(address remoteSigner_, address godGadgetForge_)
        SignerValidator(remoteSigner_)
    {
        godGadgetForge = godGadgetForge_;
    }

    /**
     * @dev Add one set of airdrop.
     */
    function addAirdrops(
        uint32 payTokenId,
        uint32 payTokenCount,
        uint32 tokenId,
        uint32 tokenCount,
        uint32 supply,
        bool requireSigner
    ) external onlyOwner {
        uint256 count = airdropCount;
        airdrops[count].payTokenId = payTokenId;
        airdrops[count].payTokenCount = payTokenCount;
        airdrops[count].tokenId = tokenId;
        airdrops[count].tokenCount = tokenCount;
        airdrops[count].supply = supply;
        airdrops[count].totalSupply = supply;
        airdrops[count].requireSigner = requireSigner;
        airdrops[count].isClaimable = false;
        airdropCount = count + 1;
    }

    /**
     * @dev Update airdrop.
     * Can only performed before it can be claimed
     */
    function updateAirdrops(
        uint256 id,
        uint32 payTokenId,
        uint32 payTokenCount,
        uint32 tokenId,
        uint32 tokenCount,
        uint32 supply,
        bool requireSigner
    ) external onlyOwner {
        require(!airdrops[id].isClaimable, "cannot modify claimable order");
        airdrops[id].payTokenId = payTokenId;
        airdrops[id].payTokenCount = payTokenCount;
        airdrops[id].tokenId = tokenId;
        airdrops[id].tokenCount = tokenCount;
        airdrops[id].supply = supply;
        airdrops[id].requireSigner = requireSigner;
    }

    /**
     * @dev Mark a airdrop claimable
     */
    function markClaimable(uint256 id) external onlyOwner {
        require(
            id < airdropCount && !airdrops[id].isClaimable,
            "cannot mark claimable"
        );
        airdrops[id].isClaimable = true;
    }

    /**
     * @dev Check whether an account is claimed 'id' of airdrop or not
     */
    function hasClaimed(address account, uint256 id)
        public
        view
        returns (bool)
    {
        return _claimed[id][account];
    }

    /**
     * @dev Batch version of hasClaimed function
     */
    function hasClaimedBatch(address account, uint256[] calldata ids)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory claims = new bool[](ids.length);
        for (uint256 index = 0; index < ids.length; ++index)
            claims[index] = _claimed[ids[index]][account];
        return claims;
    }

    /**
     * @dev Claim airdrop, must be called only from IERC1155 transfer recived handler
     */
    function _claim(
        address account,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) private {
        // decode transfer additional data
        (uint256 id, bytes memory signature) = abi.decode(
            data,
            (uint256, bytes)
        );

        // check cliamable
        require(!hasClaimed(account, id), "already claimed");
        require(airdrops[id].isClaimable, "not claimable");
        require(
            airdrops[id].payTokenCount == amount,
            "token count not correct"
        );
        require(airdrops[id].payTokenId == tokenId, "token id not correct");

        // check signer when inneeds
        if (airdrops[id].requireSigner) {
            bytes32 msgHash = keccak256(abi.encode(address(this), account, id));
            _validSignature(msgHash, signature);
        }

        // reduce supply
        uint256 supply = airdrops[id].supply - 1;
        airdrops[id].supply = uint32(supply);

        // is supply drops to 0, make aht airdrop unclaimable
        if (supply == 0) airdrops[id].isClaimable = false;

        // mark user has claim this airdrop
        _claimed[id][account] = true;
        IERC1155Minter(godGadgetForge).mint(
            account,
            airdrops[id].tokenId,
            airdrops[id].tokenCount,
            ""
        );
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        // ensure is call from Godgadget
        require(msg.sender == godGadgetForge, "only accept GodGadget transfer");
        
        // ensure is a 'human' send his own token
        require(
            operator == from && tx.origin == from,
            "should send from owner only"
        );
        _claim(from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("not allowed");
    }
}
