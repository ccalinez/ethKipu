// SPDX-License-Identifier: MIT
pragma solidity > 0.8.0;

contract Tp1EtheKipu {
     
     string private greeting;

     function getGreeting() public view returns (string memory) {
        return greeting;
     }

     function setGreeting(string calldata _greeting ) public {
        greeting = _greeting;
    }

}