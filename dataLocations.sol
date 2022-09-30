// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DataLocations {
    // Data locations - storage, memory and calldata
    struct myStruct {
        uint256 foo;
        string bar;
    }

    mapping(address => myStruct) public theMapping;

    event Fire(string);

    function StructExample() public returns (myStruct memory) {
        theMapping[msg.sender] = myStruct(19, "foobar");

        myStruct storage mystruct = theMapping[msg.sender];
        mystruct.foo = 29;

        myStruct memory readOnly = theMapping[msg.sender];
        readOnly.bar = "yadada";
        emit Fire(readOnly.bar);
        return readOnly;
    }

    function ArrayExample(uint256[] memory _numArray, string memory _s)
        external
        pure
        returns (uint256[] memory)
    {
        uint256[] memory numArray = new uint256[](3);
        numArray[0] = 1;
        numArray[2] = 19;
        numArray[3] = 29;

        return numArray;
    }

    // calldata is like memory that can be used for function inpus to save gas(as they are immutable)

    function CalldataExample(uint256[] calldata _numArr) public pure {
        _internal(_numArr);
    }

    function _internal(uint256[] calldata _numArr) private pure {
        uint256 x = _numArr[0];
    }
}
