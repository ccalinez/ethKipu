// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Auction {

    uint private completionTime;

    Stage stage;
    Bid private lastBid;
    address private admin;
    string private auctioneItem;
    
    address [] private bidders;

    mapping(address => Bid) private balances;

    event NewBid(address bidder, uint amount);
    event AuctionFinished(string indexed auctioneItem, address indexed winner, uint amount);
    event AuctionOpened(string indexed item, uint base);

    error NotEnoughHigh(string detail);
    error NothingToWithdraw();
    error AccessNotAllowed(string detail);

    struct Bid {
        bool exists;
        uint timestamp;
        uint accumulated;
        uint amount;
        address owner;
    }

    enum Stage {TakingBid, Finished }
    enum Rol {Admin, Bidder}


    constructor(uint _duration, uint base, string memory item){
        admin = msg.sender;
        auctioneItem = item;
        completionTime = block.timestamp + _duration;
        lastBid.amount = base;
        stage = Stage.TakingBid;
        emit AuctionOpened(auctioneItem, base);
    }

    function bid() external payable atStage(Stage.TakingBid)  {
        if(msg.value <= (lastBid.amount + lastBid.amount * 0.05))
            revert NotEnoughHigh("A valid bid must be 5 % greater than the last bid.");
        if(!balances[msg.sender].exists)
            bidders.push(msg.sender);

        lastBid.accumulated += msg.value;
        lastBid.amount = msg.value;
        lastBid.owner = msg.sender;
        lastBid.exists = true;
        lastBid.timestamp = block.timestamp;

        balances[msg.sender].accumulated += msg.value;
        balances[msg.sender].amount = msg.value;
        balances[msg.sender].owner = msg.sender;
        balances[msg.sender].exists = true;
        balances[msg.sender].timestamp = block.timestamp;

        emit NewBid(msg.sender, msg.value);
    }

    function withdrawal() external only(Rol.Bidder) atStage(Stage.TakingBid) {
        uint remainder = balances[msg.sender].accumulated - balances[msg.sender].amount;
        balances[msg.sender].accumulated = balances[msg.sender].amount;
        if(remainder <= 0){
            revert NothingToWithdraw();
        }
        payable(msg.sender).transfer(remainder);
    }


    modifier timedTransitions() {
        uint limit = block.timestamp < completionTime ? completionTime : lastBid.timestamp + 10 minutes;
        if (stage == Stage.TakingBid && 
                    block.timestamp > limit)
            nextStage();
        _;
    }


    function close() external only(Rol.Admin) atStage(Stage.Finished) {
        emit AuctionFinished(auctioneItem, lastBid.owner, lastBid.amount);
        for (uint i = 0; i < bidders.length; i++) {
            if(bidders[i] != lastBid.owner){
                uint amount = balances[bidders[i]].accumulated;
                amount = amount - (amount * 2) / 100;
                delete balances[bidders[i]];
                // transferir con funcion que no haga revert para usuario mas intencionado no me revierta y evite que el resto reciba su dinero
                payable(bidders[i]).transfer(amount);
            }
        }
    }

    function inforWinner() external atStage(Stage.Finished) view returns (address winner, uint amount){
        return (lastBid.owner, lastBid.amount);
    }

    function nextStage() internal {
        stage = Stage(uint(stage) + 1);
    }


    modifier only(Rol rol) {
        if(rol == Rol.Admin && msg.sender != admin)
            revert AccessNotAllowed("Only Admin User is allowed.");
        if(rol == Rol.Bidder && !balances[msg.sender].exists)
            revert AccessNotAllowed("Only Bidder are allowed.");
        _;
    }

    modifier atStage(Stage _stage) {
        if (stage != _stage)
            revert FunctionInvalidAtThisStage();
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


}