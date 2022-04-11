// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterMaker {

    /**
     * @dev Create a character for a NFT thought authorized operator
     * @param account The NFT owner.
     * @param chainSymbol The chain symbol of the token.
     * @param contractAddress The contract address of the token.
     * @param tokenId The token id.
     * @param squadLeaderId The squad of the token.
     * @return globalTokenId The global token id correspond of the token
     */
    function createCharacterThoughtOperator(
        address account,
        string calldata chainSymbol,
        address contractAddress,
        uint256 tokenId,
        uint256 squadLeaderId
    ) external returns (uint256 globalTokenId);
}
