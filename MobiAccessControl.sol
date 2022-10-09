// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AccessControl {
    address public owner;

    enum Roles {
        Admin,
        regular
    }
    // Roles public role; - may be more gas efficient on the long run...

    mapping(Roles => mapping(address => bool)) public accountToRole;
    event UpdateUserRole(address _user, Roles _role);
    event DeleteUserRole(address _user, Roles _role);
    event AuthorisedEvent(string _message);

    // We also can and should call our update role on the constructor and pass in
    // msg.sender andthe uint 0 - to make ourselves admins from the start.
    constructor() {
        owner = msg.sender; //redundant code at this point lol.
        updateRoles(msg.sender, 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Function reserved for only owner!");
        _;
    }

    modifier Authorised() {
        require(
            msg.sender == owner ||
                accountToRole[Roles.Admin][msg.sender] == true,
            "You're not authorised to call this fxn!"
        );
        _;
    }

    function updateRoles(address _user, uint256 _role) public onlyOwner {
        Roles role;
        _role == 0 ? role = Roles.Admin : role = Roles.regular;
        // Roles role = Roles.Admin;
        accountToRole[role][_user] = true;
        emit UpdateUserRole(_user, role);
    }

    function deleteRole(address _user, uint256 _role) public onlyOwner {
        Roles role;
        _role == 0 ? role = Roles.Admin : role = Roles.regular;
        delete accountToRole[role][_user];
        emit DeleteUserRole(_user, role);
    }

    function onlyAuthorised() public Authorised {
        emit AuthorisedEvent("Function works!!");
    }
}

// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
