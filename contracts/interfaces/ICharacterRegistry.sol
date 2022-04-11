// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterRegistry {
    /**
     * @dev Init a character for an exists NFT 
     * @param chainPrefix The chain symbol of the given token.
     * @param nftContract The contract address of the given token.
     * @param tokenId The given token id.
     * @param rarity The squad of the token.
     * @param totalTime The block counts that can be use as a miner. 
     */
    function initAsCharacter(
        string calldata chainPrefix,
        address nftContract,
        uint256 tokenId,
        uint256 rarity,
        uint32 totalTime
    ) external returns (uint256 randomizer, uint256 globalTokenId);

    /**
     * @dev Batch version of initAsCharacter function
     */
    function initAsCharacterBatch(
        string calldata chainPrefix,
        address nftContract,
        uint256[] calldata tokenIds,
        uint256[] calldata rarities,
        uint32 totalTime
    ) external returns (uint256[] memory randomizers, uint256[] memory globalTokenIds);

    
    /**
     * @dev Get the comosited character status, use MGPLibV2.decodeCharacter to decode as human-readable properties
     */
    function characterStats(uint256 globalTokenId) external view returns (uint256 compositeData);

    /**
     * @dev Check the given token is registred or not
     */
    function isTokenRegistred(
        string calldata chainPrefix,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

      /**
     * @dev Update the character basic properties
     */
    function updateCharacterBasic(
        uint256 globalTokenId,
        uint8 rank,
        uint8 class,
        uint32 remainingTime,
        uint32 totalTime
    ) external;

      /**
     * @dev Update the character level properties
     */
    function updateCharacterLevel(
        uint256 globalTokenId,
        uint8 level,
        uint16 strength,
        uint16 agility,
        uint16 intelligence,
        uint16 constitution,
        uint16 vitality,
        uint32 exp
    ) external;
}
