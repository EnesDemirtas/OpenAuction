// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct AuctionItem {
        address auctioneer;
        uint256 auctionEndTime;
        uint256 highestBid;
        address highestBidder;
        bool ended;
    }

    mapping(uint256 => mapping(address => Bid)) public bids;
    AuctionItem[] public auctions;

    event BidPlaced(uint256 auctionIndex, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionIndex, address winner, uint256 amount);

    modifier onlyBeforeEnd(uint256 auctionIndex) {
        require(!auctions[auctionIndex].ended, "Auction has already ended.");
	_;
    }

    modifier onlyAuctioneer(uint256 auctionIndex) {
        require(msg.sender == auctions[auctionIndex].auctioneer, "Only the auctioneer can perform this action.");
        _;
    }

    function createAuction(uint256 _duration) public {
        auctions.push(AuctionItem(msg.sender, block.timestamp + _duration, 0, address(0), false));
    }

    function placeBid(uint256 auctionIndex) public payable onlyBeforeEnd(auctionIndex) {
        AuctionItem storage auction = auctions[auctionIndex];
        require(msg.value > auction.highestBid, "Bid amount must be higher than the current highest bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        bids[auctionIndex][msg.sender] = Bid(msg.sender, msg.value);

	emit BidPlaced(auctionIndex, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionIndex) public onlyAuctioneer(auctionIndex) {
        AuctionItem storage auction = auctions[auctionIndex];
        require(!auction.ended, "Auction has already ended.");

	payable(auction.auctioneer).transfer(auction.highestBid);

        auction.ended = true;
        emit AuctionEnded(auctionIndex, auction.highestBidder, auction.highestBid);
    }
}
