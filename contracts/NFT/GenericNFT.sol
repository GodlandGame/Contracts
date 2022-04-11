// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DG4610Simple.sol";
import "../interfaces/ICharacterMaker.sol";
import "../utils/SignerValidator.sol";

/**
 * @dev A generic NFT contract base on DG4610Simple,
    and it will be create as a character on claim
 */
contract GenericNFT is DG4610Simple, SignerValidator {
    ICharacterMaker private immutable _characterMaker;
    string public chainPrefix;
    uint256 public totalSupply = 500;
    mapping(address => uint256) public claimed;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory chainPrefix_,
        address charaMaker_
    ) DG4610Simple(name_, symbol_) SignerValidator(signer_) {
        tokenIdCounter = 0;
        chainPrefix = chainPrefix_;
        _characterMaker = ICharacterMaker(charaMaker_);
    }

    /**
     * @dev Set total supply
     * @param totalSupply_ the total supply
     */
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        // ensure total supply is greater than current counter
        require(totalSupply_ >= tokenIdCounter, " total supply excceed minted");
        totalSupply = totalSupply_;
    }

    /**
     * @dev Claim NFT, create as a character and join squad
     * @param squadLeaderId the squad to join
     * @param signature the signature from server
     */
    function claim(uint256 squadLeaderId, bytes calldata signature) external nonContractCaller {
        // validate signature
        bytes32 structHash = keccak256(abi.encode(address(this), chainPrefix, msg.sender, squadLeaderId));
        _validSignature(structHash, signature);
        uint256 tokenIdCounter_ = tokenIdCounter;
        require(claimed[msg.sender] == 0, "already claimed");
        require(tokenIdCounter_ < totalSupply, "cannot mint anymore");
        claimed[msg.sender] = tokenIdCounter_ + 1;
        _mint(msg.sender);
        // create as character and join squad
        _characterMaker.createCharacterThoughtOperator(msg.sender, chainPrefix, address(this), tokenIdCounter_, squadLeaderId);
    }

    modifier nonContractCaller() {
        require(tx.origin == msg.sender, "cannot call from contract");
        _;
    }
}
