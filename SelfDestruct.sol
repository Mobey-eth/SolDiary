// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract selfDestruct {
    // self destruct
    // - delete contracts
    // - used to force send ETH to any address...

    constructor() payable {}

    function kill() external {
        selfdestruct(payable(msg.sender));
    }

    function testerFunc() external pure returns (uint256 _Num) {
        return 19;
    }
}

contract Helper {
    function getBal() external view returns (uint256) {
        return address(this).balance;
    }

    function testerFunc() external pure returns (uint256 _Num) {
        return 19;
    }

    function executekill(address _address) external {
        selfDestruct _kill = selfDestruct(_address);
        _kill.kill();
    }

    function executekillfxn(selfDestruct _kill) external {
        _kill.kill();
    }
}
