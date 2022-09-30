// SPDX-License-Identifier: MIT
pragma solidity ^0.5.11;

contract reciever {
    uint256 public finalNum;
    event fooEvent(address sender, string message, uint256 amount);

    function foo(string memory _message, uint256 _num)
        public
        payable
        returns (uint256)
    {
        emit fooEvent(msg.sender, _message, msg.value);
        finalNum = _num + 1;
        return finalNum;
    }

    function() external payable {
        emit fooEvent(msg.sender, "Fallback was called", msg.value);
    }
}

contract caller {
    event Response(bool success, bytes data);

    function testCallFoo(address payable _addr) public payable {
        (bool success, bytes memory data) = _addr.call.value(msg.value).gas(
            50000
        )(abi.encodeWithSignature("foo(string,uint256)", "calling foo", 19));
        emit Response(success, data);
    }

    function testCallDoesntExist(address _addr) public {
        (bool success, bytes memory data) = _addr.call.gas(5000)(
            abi.encodeWithSignature("doesNotExist()")
        );
        emit Response(success, data);
    }

    /*

    event Response( bool success, bytes32 data);

    function testCallFoo(address _addr) external payable {
        (bool success , bytes memory data)= _addr.call.value(msg.value).gas(5000)(abi.encodeWithSignature("foo(string,uint256)", "Calling foo", 19);
        emit Respnse(success, data);
    }
    */
}
// OLD CALL IMPLEMENTATION!
