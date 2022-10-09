// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestMultiCall {
    function func1() public view returns (uint256, uint256) {
        return (1, block.timestamp);
    }

    function func2() public view returns (uint256, uint256) {
        return (2, block.timestamp);
    }

    function getCallData1() public pure returns (bytes memory) {
        return abi.encodeWithSignature("func1()");
    }

    function getCallData2() public pure returns (bytes memory) {
        return abi.encodeWithSelector(this.func2.selector);
    }
}

contract MobiMultiCall {
    // address[] public contractAddresses;

    // bytes[] public data;
    // constructor(address[] memory _contractAddrs, bytes[] memory _data) {}
    event log(bytes returnData);

    function multicall(address[] memory _contractAddrs, bytes[] calldata _data)
        external
    {
        require(_contractAddrs.length == _data.length, "No of Inputs mismatch");
        for (uint256 i; i < _contractAddrs.length; i++) {
            address _addr = _contractAddrs[i];
            bytes calldata dataa = _data[i];
            (bool success, bytes memory data) = _addr.call(dataa);
            require(success, "call failed!");
            emit log(data);
        }
    } // My Implementation.
}

contract MultiCall {
    function multicall(address[] memory _contractAddrs, bytes[] calldata _data)
        external
        view
        returns (bytes[] memory)
    {
        require(_contractAddrs.length == _data.length, "No of Inputs mismatch");

        bytes[] memory results = new bytes[](_data.length);

        for (uint256 i; i < _contractAddrs.length; i++) {
            address _addr = _contractAddrs[i];
            bytes calldata dataa = _data[i];
            (bool success, bytes memory result) = _addr.staticcall(dataa);
            require(success, "call failed!");
            results[i] = result;
        }
        return results;
    } // tut Implementation.
}
