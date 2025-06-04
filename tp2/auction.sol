// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Auction {

    address admin;
    string auctioneItem;
    uint256 completionTime;
    uint basePrice;
    Bid lastBid;
    address [] bidders;

    mapping(address => Bid) balances;

    event NewBid(address bidder, uint amount);
    event AuctionFinished(string indexed auctioneItem, address indexed winner, uint amount);
    event AuctionOpened(string indexed item, uint base);


    struct Bid {
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
        emit AuctionOpened(auctioneItem, basePrice);
    }

    function bid() external payable active greatter {
        if(!balances[msg.sender].exists){
            bidders.push(msg.sender);
        }
        lastBid.accumulated += msg.value;
        lastBid.amount = msg.value;
        lastBid.owner = msg.sender;
        lastBid.exists = true;
        lastBid.timestamp = block.timestamp;
        balances[msg.sender] = lastBid;
        emit NewBid(msg.sender, msg.value);
    }

    function close() external onlyAdmin finished {
        emit AuctionFinished(auctioneItem, lastBid.owner, lastBid.amount);
        for (uint i = 0; i < bidders.length; i++) {
            if(bidders[i] != lastBid.owner){
                uint amount = balances[bidders[i]].accumulated;
                amount = amount - (amount * 2) / 100;
                balances[bidders[i]].accumulated = 0;
                payable(bidders[i]).transfer(amount);
            }
        }
    }

    function withdrawal() external onlyBidder active {
        uint256 amount = balances[msg.sender].accumulated - balances[msg.sender].amount;
        balances[msg.sender].accumulated = balances[msg.sender].amount;
        payable(msg.sender).transfer(amount);
    }

    function inforWinner() external finished view returns (address winner, uint amount){
        return (lastBid.owner, lastBid.amount);
    }


    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin User is allowed.");
        _;
    }

    modifier finished {
        require(block.timestamp > completionTime && block.timestamp > (lastBid.timestamp + 10 minutes),
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
        }else if(lastBid.exists && block.timestamp < (lastBid.timestamp + 10 minutes)){
            isActive = true;
        }
        require(isActive, "The time for place a bid has finish");
        _;
    }

    // modificador que verifica una oferta mayor al 5% de la ultima oferta
    modifier greatter {
        bool valid = false;
        if(lastBid.exists && msg.value > (lastBid.amount + (lastBid.amount * 5) / 100)){
            valid = true;
        }else if(msg.value > (basePrice + (basePrice * 5) / 100)){
            valid = true;
        }
        require(valid, "A valid bid must be 5 % greater than the last bid.");
        _;
    }

}