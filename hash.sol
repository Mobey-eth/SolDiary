// SPDX-License-Identifier: MIT

pragma solidity ^0.5.11;

contract HashFunction {
    bytes32 public hash;

    function hashStuff(uint256 _num) public returns (bytes32) {
        hash = keccak256(
            abi.encodePacked(
                uint256(_num),
                "Moby Here",
                address(msg.sender),
                bool(true)
            )
        );
        return hash;
    }
}

contract GuessThatWord {
    bytes32 hash;
    string public Word;
    string public LastUserInput;

    event Winner(address _winner, string _message);
    event UserTrial(address _user, string _message);

    constructor() public {
        Word = "Peacemaker";
        setHash();
    }

    modifier checkEntrance() {
        require(msg.value == 100 * 10**9, "entrance fee is 100 GWEI!");
        _;
    }

    function setHash() internal {
        hash = keccak256(abi.encodePacked(Word));
    }

    function getPoolBal() public view returns (uint256) {
        return address(this).balance;
    }

    function guessHash(string memory _input) public payable checkEntrance {
        LastUserInput = _input;
        bytes32 userHash = keccak256(abi.encodePacked(LastUserInput));
        if (userHash == hash) {
            emit Winner(msg.sender, "Congratulations, you win!");
            (msg.sender).transfer(getPoolBal());
        } else {
            emit UserTrial(msg.sender, "Unlucky That time, Try again!");
        }
    }
}
