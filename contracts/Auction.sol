	// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    // Structure to represent a bid
    struct Bid {
        address bidder;
        uint256 amount;
    }

    // Auction details
    address public auctioneer;
    uint256 public auctionEndTime;
    uint256 public highestBid;
    address public highestBidder;
    bool public ended;

    // Mapping to store bids
    mapping(address => Bid) public bids;

        // Modifier to check if the auction has ended
    modifier onlyBeforeEnd() {
        require(!ended, "Auction has already ended.");
        _;
    }

    // Modifier to check if the caller is the auctioneer
    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Only the auctioneer can perform this action.");
        _;
    }


    constructor(uint256 _durationByHour) {
        auctioneer = msg.sender;
        auctionEndTime = block.timestamp + _durationByHour * 1 hours;
    }

    // Function to place a bid
    function placeBid() public payable onlyBeforeEnd{
        require(msg.value > highestBid, "Bid amount must be higher than the current highest bid.");

        // If there was a previous highest bidder, refund their bid
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        // Update the highest bid and bidder
        highestBid = msg.value;
        highestBidder = msg.sender;

        // Store the bid
        bids[msg.sender] = Bid(msg.sender, msg.value);
    }

    // Function to end the auction and declare the winner
    function endAuction() public onlyAuctioneer{
        require(!ended, "Auction has already ended.");

        // Transfer the highest bid amount to the auctioneer
        payable(auctioneer).transfer(highestBid);

        ended = true;
    }
}