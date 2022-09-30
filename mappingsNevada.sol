// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Nevada {
    uint256 public totPeople;
    struct Person {
        string name;
        uint256 age;
    }

    Person[] public people;
    mapping(string => uint256) public nameToAge;
    mapping(uint256 => Person) public personMapping;

    function addPerson(string memory _name, uint256 _age) public {
        people.push(Person(_name, _age));
        nameToAge[_name] = _age;
        totPeople++;
        personMapping[totPeople] = Person(_name, _age);
    }
}
