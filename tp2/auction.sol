// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Auction {

    address admin;
    string auctioneItem;
    uint256 completionTime;
    uint minimumBid;
    uint32 price;
    uint32 extraTime;




    constructor(string memory item, uint32 duration, uint32 basePrice){
        admin = msg.sender;
        auctioneItem = item;
        completionTime = block.timestamp + duration;
        price = basePrice;
    }

    function bit() external payable {

    }

}