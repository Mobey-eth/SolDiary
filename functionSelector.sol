// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract functionSelector {
    function getfunctionSelector(string calldata _func)
        public
        pure
        returns (bytes4 data)
    {
        data = bytes4(keccak256(bytes(_func))); // cast the input string as bytes
    }
}

contract TestTransfer {
    event log(bytes data);

    function transfer(address _to, uint256 amount) public {
        emit log(msg.data);
    }
}

/*
msg.data =>
    function selector = 0xa9059cbb -- first 4bytes encodes the function to call...
    address bytes = 0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4
    amount in bytes = 000000000000000000000000000000000000000000000000000000000000000b

    string input => "transfer(address,uint256)"

*/
