// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Auction {

    address admin;
    string auctioneItem;
    uint256 completionTime;
    uint basePrice;
    Bit lastBit;

    mapping(address => Bit) balances;


    struct Bit {
        address owner;
        uint256 timestamp;
        uint256 accumulated;
        uint256 amount;
        bool exists;
    }


    constructor(string memory _item, uint32 _duration, uint32 _basePrice){
        admin = msg.sender;
        auctioneItem = _item;
        completionTime = block.timestamp + _duration;
        basePrice = _basePrice;
    }

    function bit() external payable active greatter {
        lastBit.accumulated += msg.value;
        lastBit.amount = msg.value;
        lastBit.owner = msg.sender;
        lastBit.exists = true;
        lastBit.timestamp = block.timestamp;
        balances[msg.sender] = lastBit;
    }

    function returnFunds() external onlyAdmin finished {

    }

    function withdrawal() external onlyBidder active {
        uint256 amount = balances[msg.sender].accumulated - balances[msg.sender].amount;
        balances[msg.sender].accumulated = balances[msg.sender].amount;
        payable(msg.sender).transfer(amount);
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin User is allowed.");
        _;
    }

    modifier finished {
        require(block.timestamp > completionTime && block.timestamp > (lastBit.timestamp + 10 minutes),
        "The auction has not ended yet.");
        _;
    }

    // modificador que valida que solo ofertante con deposito pueda retirar el dinero
    modifier onlyBidder {
        require(balances[msg.sender].exists, "Only Bidder are allowed.");
        _;
    }

    // modificador que verifica que se pueda aplicar una oferta  10 minutos antes que finalice la subasta 
    // o durante los 10 minutos posteriores de la ultima oferta pasado el tiempo de finalizacion de la subasta
    modifier active {
        bool isActive = false;
        if(block.timestamp < (completionTime - 10 minutes)){
            isActive = true;
        }else if(lastBit.exists && block.timestamp < (lastBit.timestamp + 10 minutes)){
            isActive = true;
        }
        require(isActive, "The time for place a bid has finish");
        _;
    }

    // modificador que verifica una oferta mayor al 5% de la ultima oferta
    modifier greatter {
        bool valid = false;
        if(lastBit.exists && msg.value > (lastBit.amount + (lastBit.amount * 5) / 100)){
            valid = true;
        }else if(msg.value > (basePrice + (basePrice * 5) / 100)){
            valid = true;
        }
        require(valid, "A valid bid must be 5 % greater than the last bid.");
        _;
    }

}