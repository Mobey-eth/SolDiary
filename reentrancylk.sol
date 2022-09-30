// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestRun {
    uint256 public num = 10;
    bool locked;

    modifier nonReentrancy() {
        // default value of locked = false
        require(!locked, "function is locked!");
        locked = true;
        _;
        locked = false;
    }

    function decrement(uint256 x) public nonReentrancy {
        num -= x;

        if (x > 1) {
            decrement(x - 1);
        }
    }
}
