// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A randomizer for generate a simple random number
 */
contract Randomizer {
    uint256 private _randomizer;

    constructor(uint256 salt_) {
        _randomizer = salt_ ^ genRandomNumber();
    }

    function genRandomNumber() public returns (uint256) {
        uint256 tempo = uint256(blockhash(block.number - 1)) ^ _randomizer;
        bytes memory data = new bytes(32);
        assembly {
            mstore(add(data, 32), tempo)
        }
        tempo = uint256(keccak256(data));
        _randomizer ^= tempo;
        return tempo;
    }
}
