// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A randomizer for generate a simple random number
 */
contract Randomizer {
    function genRandomNumber() public view returns (uint256) {
        uint256 tempo = uint256(blockhash(block.number - 1)) ^ uint256(uint160(address(block.coinbase))) ^ uint256(uint160(msg.sender)) ^ gasleft();
        bytes memory data = new bytes(32);
        assembly {
            mstore(add(data, 32), tempo)
        }
        tempo = uint256(keccak256(data));
        return tempo;
    }
}
