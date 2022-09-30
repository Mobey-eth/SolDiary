// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract wallet {
    bytes32 public hash;
    address public owner;
    event receivedETH(address indexed _sender, uint256 value, uint256 gasLeft);
    event sentETH(address indexed _reciever, uint256 value);

    constructor(string memory _password) payable {
        owner = msg.sender;
        setPassword(_password);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Function reserved for only Owner");
        _;
    }

    receive() external payable {
        emit receivedETH(msg.sender, msg.value, gasleft());
    }

    function setPassword(string memory _password) public onlyOwner {
        hash = keccak256(abi.encodePacked(_password));
    }

    function getBal() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function sendEth(
        string calldata _password,
        address _to,
        uint256 _value
    ) external payable onlyOwner {
        require(_value > 0, "Value cannot be less than 0");
        bytes32 _hashinput = keccak256(abi.encodePacked(_password));
        require(_hashinput == hash, "Incorrect password!");
        payable(_to).transfer(_value);
        emit sentETH(_to, _value);
    }
}

contract SendETH {
    receive() external payable {}

    function sendETH(address payable _to, uint256 _value) public payable {
        (bool success, ) = _to.call{value: _value}("");
        require(success, "failed");
    }
}
