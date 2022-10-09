// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 1.1 - Create 2 allows @dev to compute the addess of a contract before it is deployed.
    we specify a salt(random number) and cast it to a bytes 32.
    
    - For the getAddress function, we hash the encoded arguments of bytes1(0xff),
        the address of the deployer, the salt and the hash of the bytecode of the contract
*/

contract DeployWithCreate2 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract Create2Fatctory {
    event Deploy(address contractAddr);

    function deploy(uint256 _salt) external {
        DeployWithCreate2 createContract = new DeployWithCreate2{
            salt: bytes32(_salt)
        }(msg.sender); // 1.1
        emit Deploy(address(createContract));
    }

    function getAddress(bytes memory bytecode, uint256 _salt)
        external
        view
        returns (address contractAddr)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );
        contractAddr = address(uint160(uint256(hash)));
        // address is the last 20bytes of the hash, so we cast hash to uint and uint160
        // we'd then get the address from the uint160.
    }

    function getBytecode(address _owner) external pure returns (bytes memory) {
        bytes memory bytecode = type(DeployWithCreate2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
        // if constructor args, we encode the args,
        // and encodePacked the bytecode and the encoded agrs.
    }
}
