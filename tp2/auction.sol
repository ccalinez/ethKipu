// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;
/**
* @title Auction Contract. Module 2 Final Project
* @author Cristian Alinez
* @notice This contract manages an Auction allowing bidders to place a higher bid to win the item up for auction.
 */
contract Auction {

    // state variables declaration  
    uint private completionTime;
    Stage private stage;
    Bid private lastBid;
    address private admin;
    string private auctioneItem;
    address [] private bidders;
    mapping(address => Bid) private balances;

    // events definition
    event NewBid(address bidder, uint amount);
    event AuctionFinished(string indexed auctioneItem, address indexed winner, uint amount);
    event AuctionOpened(string indexed item, uint base);

    // errors definition
    error NotEnoughHigh(string detail);
    error NothingToWithdraw();
    error AccessNotAllowed(string detail);
    error NotAllowedAtStage(Stage stage);

    /**
    * @title Structure that represents a Pid place by a bidder
    * @author Cristian Alinez
    * @notice 
    */
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

    function bid() external payable timedTransitions atStage(Stage.TakingBid)  {
        if(msg.value <= (lastBid.amount + ((lastBid.amount * 5) / 100)))
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

    function withdrawal() external timedTransitions only(Rol.Bidder) atStage(Stage.TakingBid)  {
        uint remainder = balances[msg.sender].accumulated - balances[msg.sender].amount;
        balances[msg.sender].accumulated = balances[msg.sender].amount;
        if(remainder <= 0){
            revert NothingToWithdraw();
        }
        payable(msg.sender).transfer(remainder);
    }


    modifier timedTransitions() {
        uint limit = block.timestamp < completionTime ? completionTime : lastBid.timestamp + 10 minutes;
        if (stage == Stage.TakingBid && block.timestamp > limit)
            nextStage();
        _;
    }


    function close() external only(Rol.Admin) atStage(Stage.Finished) {
        emit AuctionFinished(auctioneItem, lastBid.owner, lastBid.amount);
        for (uint i = 0; i < bidders.length; i++) {
            if(bidders[i] != lastBid.owner){
                Bid memory aux = balances[bidders[i]];
                uint amount = balances[bidders[i]].accumulated;
                amount = amount - (amount * 2) / 100;
                delete balances[bidders[i]];
                // transferir con funcion que no haga revert para usuario mas intencionado no me revierta y evite que el resto reciba su dinero
                if(!payable(bidders[i]).send(amount)){
                    balances[bidders[i]] = aux;
                }
            }
        }
    }

    function showWinner() external atStage(Stage.Finished) view returns (address winner, uint amount){
        return (lastBid.owner, lastBid.amount);
    }

    function showBids() external view atStage(Stage.TakingBid) returns (Bid [] memory){
        Bid [] memory bids   = new Bid [](bidders.length);
        for(uint i = 0; i < bidders.length; i++){
            bids[i] = balances[bidders[i]];
        }
        return bids;
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
            revert NotAllowedAtStage(stage);
        _;
    }
}