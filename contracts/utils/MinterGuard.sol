// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev A simple minter control base
 */
abstract contract MinterGuard is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    /**
     * @dev Add a minter.
     * @param minter The minter to add.
     */
    function addMinter(address minter) external onlyOwner {
        require(_minters.add(minter), "already a minter");
    }

    /**
     * @dev Remove a minter.
     * @param minter The minter to remove.
     */
    function removeMinter(address minter) external onlyOwner {
        require(_minters.remove(minter), "not a minter");
    }

    /**
     * @dev Retrive all minters
     */
    function minters() external view returns (address[] memory minters_) {
        uint256 count = _minters.length();
        minters_ = new address[](count);
        for (uint256 index = 0; index < count; ++index)
            minters_[index] = _minters.at(index);
    }

    /**
     * @dev Modifier for minter allowance
     */
    modifier onlyMinter() {
        require(_minters.contains(msg.sender), "require minter");
        _;
    }
}
