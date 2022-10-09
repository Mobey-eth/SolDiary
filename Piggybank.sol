// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MobiAccessControl.sol";

contract piggyBank is AccessControl {
    constructor() payable {}

    event deposit(address indexed _sender, uint256 _value, uint256 _gasLeft);

    receive() external payable {
        balances += msg.value;
        emit deposit(msg.sender, msg.value, gasleft());
    }

    uint256 public balances;

    function withdraw(address _address) external Authorised {
        selfdestruct(payable(_address));
    }

    function testerFunc() external view Authorised returns (uint256 _Num) {
        return 19;
    }
}
