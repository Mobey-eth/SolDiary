// SPDX-License-Identifier: MIT

pragma solidity ^0.5.11;

contract A {
    uint256 public num;
    address public sender;
    uint256 public value;

    event Response(bool success, bytes data);

    function setVars(address _contract, uint256 _num) external payable {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        emit Response(success, data);
    }
}

contract B {
    uint256 public num;
    address public sender;
    uint256 public value;

    event DelegateEvent(address indexed sender, uint256 value);

    function setVars(uint256 _num) public payable returns (uint256) {
        num += _num + 1;
        emit DelegateEvent(msg.sender, msg.value);
        return num;
    }
}

contract B2 {
    uint256 public num;
    address public sender;
    uint256 public value;

    event DelegateEvent(address indexed sender, uint256 value);

    function setVars(uint256 _num) public payable returns (uint256) {
        num += _num + 10;
        emit DelegateEvent(msg.sender, msg.value);
        return num;
    }
}
