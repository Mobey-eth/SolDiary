// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VerifySignature {
    /* To sign a message

    1. hash(message)
    2. sign(hash(message), private key) | -done offchain
    3. ecrecover(hash(message), signature) == signer
*/

    // for complexity purposes, I'll sign a string message
    function verifySig(
        address _signer,
        string calldata _message,
        bytes memory _sig
    ) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        // To get the ethsigned messageHash -offchain stuff
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        // We take the ethSignedMessageHash and verify it with the signature,
        // recover the signer and check it against the provided address of signer.
        return recover(ethSignedMessageHash, _sig) == _signer;
    }

    function getMessageHash(string calldata _message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r, /* 32 length(bytes)*/
            bytes32 s, /* 32 length(bytes)*/
            uint8 v /* 1 length(bytes)*/
        )
    {
        require(_sig.length == 65, "Invalid signature input");
        // 1.1
        assembly {
            r := mload(add(_sig, 32)) // 1.2
            s := mload(add(_sig, 64)) // 1.3
            v := byte(0, mload(add(_sig, 96))) // 1.4
        }
    }

    /* Notes
        --------------

        1.1 - _sig is a dynamic data as it has a dynamic length
                the first 32 bytes stores the length of the data. 
                _sig is not the actual SIGNATURE but its a pointer to where the
                signature is stored in memory.

        1.2 - r will load to memory 32 bytes from the input pointer...
                we skip the first 32 bytes as it stores the length of the array

        1.3 - for s , we skip the first 64 bytes as it stores the length of the array, 
                and holds the value for r.

        1.4 - for v , we skip the first 96 bytes as it stores the length of the array, 
                and holds the value for r and s . we also only need the first byte so we cast it in a bytes(0, ...)
     
     */
}

// Test in brownie or web3.py...
