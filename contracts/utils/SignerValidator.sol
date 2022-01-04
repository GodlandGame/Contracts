// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev A sign verifier base.
 */
abstract contract SignerValidator {
    address public remoteSigner;

    constructor(address remoteSigner_) {
        _setRemoteSigner(remoteSigner_);
    }

    /**
     * @dev Set signer's addres for ECDSA address recover verification.
     * @param remoteSigner_ The signer's address.
     */
    function _setRemoteSigner(address remoteSigner_) internal {
        remoteSigner = remoteSigner_;
    }

    /**
     * @dev Verify signature
     * @param msgHash The original hashed message.
     * @param signature The signature to verify.
     */
    function _validSignature(bytes32 msgHash, bytes memory signature) internal view {
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(msgHash), signature);
        require(signer == remoteSigner, "invalid signature");
    }
}
