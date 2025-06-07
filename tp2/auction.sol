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
    /**
    * @notice Event emitted when a new bid is placed in the Auction.
    * @param bidder bidder Address of the user placing a new Bid.
    * @param amount Amount of the Bid placed.
    */
    event NewBid(address indexed bidder, uint amount);

    /**
    * @notice Event emitted when the auction is over and a winner was found.
    * @param auctioneItem Name of the Item on which was the Auction.
    * @param winner Bidder Address of the highest bid.
    * @param amount Amount of the highest bid.
    */
    event AuctionFinished(string indexed auctioneItem, address indexed winner, uint amount);
    /**
    * @notice Event emitted when the auction is open and bids are placed.
    * @param item Name of the Item on which was the Auction.
    * @param base Initial value of the Auction
    */
    event AuctionOpened(string indexed item, uint base);

    // errors definition
    /**
    * @notice Error that is thrown when a bid is lower than 5% greater of the previous bid
    * @param detail Error detail
    */
    error NotEnoughHigh(string detail);

    /**
    * @notice Error that is thrown when a bidder tries to withdraw remaining funds that you do not have
    */
    error NothingToWithdraw();

    /**
    * @notice Error that is thrown when the user does not have a valid role to perform this action.
    * @param detail Error detail
    */
    error AccessNotAllowed(string detail);

    /**
    * @notice Error that is thrown when the user tries to perform an action not allowed in the current stage.
    * @param stage Current stage
    */
    error NotAllowedAtStage(Stage stage);

    /**
    * @notice Error that is thrown when no bid has been placed and the Auction has ended without a bid.
    */
    error NotWinningBid();

    // Struts definition
    /**
    * @title Bid struct
    * @author Cristian Alinez
    * @notice Structure that represents a Bid placed by a bidder
    */
    struct Bid {
        bool exists;
        uint timestamp;
        uint accumulated;
        uint amount;
        address owner;
    }

    // Enums definitions
    /**
    * @title Stage enum
    * @author Cristian Alinez
    * @notice Enum that represents the stages through which an auction takes place
    */
    enum Stage {TakingBid, Finished }

    /**
    * @title Rol enum
    * @author Cristian Alinez
    * @notice Enum that represents the roles for the auction users
    */
    enum Rol {Admin, Bidder}

    /**
    * @author Cristian Alinez
    * @notice Constructor that setup the auction configuration and announces the opening of the auction
    * @param  duration Time limit in seconds until valid bids are accepted
    * @param  base Initial value of the bid
    * @param  item Name of the auction Item
    */
    constructor(uint duration, uint base, string memory item){
        admin = msg.sender;
        auctioneItem = item;
        completionTime = block.timestamp + duration;
        lastBid.amount = base;
        stage = Stage.TakingBid;
        emit AuctionOpened(auctioneItem, base);
    }

    /**
    * @notice Function that places a bid on the auction, it will revert with an error code in case of bid isn't a 5% higher than the last one.
    */
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

    /**
    * @notice Function that allows bidders to withdraw the remaining funds from the last bid. It will reverse with an error code if the bidder has no remaining funds to withdraw.
    */
    function withdrawal() external timedTransitions only(Rol.Bidder) atStage(Stage.TakingBid)  {
        uint remainder = balances[msg.sender].accumulated - balances[msg.sender].amount;
        balances[msg.sender].accumulated = balances[msg.sender].amount;
        if(remainder <= 0){
            revert NothingToWithdraw();
        }
        payable(msg.sender).transfer(remainder);
    }


    /**
    * @notice Function that closes the auction and transfers all remaining funds to the bidders that didn't won the auction, taking 2% as commission.
    */
    function close() external only(Rol.Admin) atStage(Stage.Finished) {
        if(!lastBid.exists){
            emit AuctionFinished(auctioneItem, address(0), 0);
            return;
        }  
        emit AuctionFinished(auctioneItem, lastBid.owner, lastBid.amount);
        for (uint i = 0; i < bidders.length; i++) {
            if(bidders[i] != lastBid.owner){
                uint amount = balances[bidders[i]].accumulated;
                balances[bidders[i]].accumulated = 0;
                if(!payable(bidders[i]).send(amount - (amount * 2) / 100)){
                    balances[bidders[i]].accumulated = amount;
                }
            }
        }
    }

    /**
    * @notice Function tha allow to get the address of the highest bidder, the amount of his bids, if he has been placed any bid or not.
    * @return winner Winner bid address
    * @return amount Winner bid amount
    */
    function showWinner() external atStage(Stage.Finished) view returns (address winner, uint amount){
         if(!lastBid.exists){
            revert NotWinningBid();
        }
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

    modifier timedTransitions() {
        uint limit = block.timestamp < completionTime ? completionTime : lastBid.timestamp + 10 minutes;
        if (stage == Stage.TakingBid && block.timestamp > limit)
            nextStage();
        _;
    }

}