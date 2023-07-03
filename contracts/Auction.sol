// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct AuctionItem {
        address auctioneer;
        string itemName;
        uint256 auctionEndTime;
        uint256 reservePrice;
        uint256 highestBid;
        address highestBidder;
        bool ended;
        bool cancelled;
    }

    mapping(uint256 => mapping(address => Bid)) public bids;
    AuctionItem[] public auctions;

    event BidPlaced(uint256 auctionIndex, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionIndex, address winner, uint256 amount);
    event AuctionCancelled(uint256 auctionIndex);

    modifier onlyBeforeEnd(uint256 auctionIndex) {
        require(!auctions[auctionIndex].ended, "Auction has already ended.");
	_;
    }

    modifier onlyNotCancelled(uint256 auctionIndex) {
        require(!auctions[auctionIndex].cancelled, "Auction has been cancelled.");
        _;
    }

    modifier onlyAuctioneer(uint256 auctionIndex) {
        require(msg.sender == auctions[auctionIndex].auctioneer, "Only the auctioneer can perform this action.");
        _;
    }

    function createAuction(string memory _itemName, uint256 _durationByMinute, uint256 _reservePrice) public {
        require(_durationByMinute > 0, "Auction duration must be greater than zero.");
        auctions.push(AuctionItem(msg.sender, _itemName, block.timestamp + 1 minutes * _durationByMinute, _reservePrice * 1 ether, 0, address(0), false, false));
    }

    function placeBid(uint256 auctionIndex) public payable onlyBeforeEnd(auctionIndex) onlyNotCancelled(auctionIndex) {
        AuctionItem storage auction = auctions[auctionIndex];
        require(msg.value > auction.highestBid, "Bid amount must be higher than the current highest bid.");
        require(msg.value >= auction.reservePrice, "Bid amount must meet or exceed the reserve price.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        bids[auctionIndex][msg.sender] = Bid(msg.sender, msg.value);

	emit BidPlaced(auctionIndex, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionIndex) public onlyAuctioneer(auctionIndex) onlyBeforeEnd(auctionIndex) onlyNotCancelled(auctionIndex) {
        AuctionItem storage auction = auctions[auctionIndex];
        require(auction.highestBidder != address(0), "Auction cannot be ended with no bids.");

	payable(auction.auctioneer).transfer(auction.highestBid);

        auction.ended = true;
        emit AuctionEnded(auctionIndex, auction.highestBidder, auction.highestBid);
    }

    function cancelAuction(uint256 auctionIndex) public onlyAuctioneer(auctionIndex) onlyBeforeEnd(auctionIndex) onlyNotCancelled(auctionIndex) {
        AuctionItem storage auction = auctions[auctionIndex];
        auction.cancelled = true;
        emit AuctionCancelled(auctionIndex);
    }

    function getAuctionDetails(uint256 auctionIndex) public view returns (
        address auctioneer,
        string memory itemName,
        uint256 auctionEndTime,
        uint256 reservePrice,
        uint256 highestBid,
        address highestBidder,
        bool ended,
        bool cancelled
    ) {
        AuctionItem storage auction = auctions[auctionIndex];
        return (
            auction.auctioneer,
            auction.itemName,
            auction.auctionEndTime,
            auction.reservePrice,
            auction.highestBid,
            auction.highestBidder,
            auction.ended,
            auction.cancelled
        );
    }

    function getAuctions() public view returns(AuctionItem[] memory) {
        AuctionItem[] memory result = new AuctionItem[](auctions.length);
        for (uint i = 0; i < auctions.length; i++) {
            result[i] = auctions[i];
        }
        return result;
    }
}