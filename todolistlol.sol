// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Todo {
    struct TODO {
        string task;
        bool completed;
    }

    TODO[] public todos;

    function create(string calldata _task) public {
        todos.push(TODO(_task, false));
    }

    function completeTask(uint256 _index, bool _status) public {
        todos[_index].completed = _status;
    }

    function updateTask(uint256 _index, string calldata _task) public {
        TODO storage _todo = todos[_index];
        _todo.task = _task;
    }
}
