// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestContract1 {
    event NewOwner(address _newOwner);
    address public owner = msg.sender;

    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only Owner can call this fxn!");
        require(_owner != address(0), "Owner cannot be the Zero Address");
        owner = _owner;
        emit NewOwner(owner);
    }
}

contract TestContract2 {
    uint256 public x;
    uint256 public y;
    address public owner;
    uint256 public value;

    constructor(uint256 _x, uint256 _y) payable {
        x = _x;
        y = _y;

        owner = msg.sender;
        value = msg.value;
    }
}

contract Proxy {
    event DeployEvent(address);

    fallback() external payable {}

    // To deploy a contract by passing in the bytecode of the contract
    function deploy(bytes memory _code)
        external
        payable
        returns (address addr)
    {
        assembly {
            // create(v, p, n)
            // v = amount of ETH to send
            // p = pointer in memory to start of code
            // n = size of code

            // ---------------
            // where msg.value = callvalue()
            // we also need to skip the first 32 bytes from _code cus the actual code starts after that

            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }
        require(addr != address(0), "deploy failed!");
        emit DeployEvent(addr);
    }

    function execute(address _targetContract, bytes memory _data)
        external
        payable
    {
        (bool success, ) = _targetContract.call{value: msg.value}(_data);
        require(success, "failed!");
    }
}

contract Helper {
    function getBytecode() external pure returns (bytes memory) {
        bytes memory bytecode = type(TestContract1).creationCode;
        return bytecode;
    }

    function getBytecode2(uint256 _x, uint256 _y)
        external
        pure
        returns (bytes memory)
    {
        bytes memory bytecode = type(TestContract2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_x, _y));
    }

    function getCallData(address _owner) external pure returns (bytes memory) {
        bytes memory _bytes = abi.encodeWithSignature(
            "setOwner(address)",
            _owner
        );
        return _bytes;
    }
}
