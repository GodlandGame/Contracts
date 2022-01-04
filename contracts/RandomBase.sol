// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRandomizer.sol";

/**
 * @dev A random number provider base for Godland. Accept a randomizer contract as random generator 
 */
abstract contract RandomBase {
    IRandomizer private _randomizer;

    constructor(address randomizer_) {
        _randomizer = IRandomizer(randomizer_);
    }

    // get random number
    function _genRandomNumber() internal returns (uint256) {
        return _randomizer.genRandomNumber();
    }
}
