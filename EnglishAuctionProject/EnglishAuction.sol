// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract EnglishAuction {
    IERC721 public immutable nftContract;
    address public immutable seller;
    bool public Started;
    bool public Ended;
    uint256 public EndAT;
    uint256 public highestBid;
    address public highestBidder;

    mapping(address => uint256) public bids;
    mapping(address => bool) public isBidder;
    mapping(uint256 => bool) public tokenIdExists;

    event AuctionStarted(uint256 startTime);
    event Bid(address indexed NewBidder, uint256 amount, uint256 TokenId);
    event Withdrawal(address indexed Bidder, uint256 amount);
    event AuctionEnded(
        address buyer,
        address seller,
        uint256 sellAmount,
        uint256 TokenId
    );
    event RevokedBid(address highestBidder, uint256 amount, uint256 TokenID);

    constructor(address _tokenAddress, uint256 _startingBid) {
        nftContract = IERC721(_tokenAddress);
        seller = msg.sender;
        highestBid = _startingBid;
    }

    function startAuction(uint256 _tokenID) public {
        require(msg.sender == seller, "Only seller should start auction");
        require(!Started, "Auction is alread started.");
        uint256 StartAt = block.timestamp;
        EndAT = block.timestamp + 300;

        nftContract.transferFrom(seller, address(this), _tokenID);
        tokenIdExists[_tokenID] = true;
        Started = true;
        emit AuctionStarted(StartAt);
    }

    function bid(uint256 _tokenID) external payable {
        require(block.timestamp < EndAT, "Auction already Ended!");
        require(
            msg.sender != seller && msg.sender != address(0),
            "Invalid Bidder!"
        );
        require(msg.value >= highestBid, "bid is lower than the highest bid!");
        require(tokenIdExists[_tokenID], "TokenID isn't up for auction! ");

        bids[msg.sender] += msg.value;
        highestBid = msg.value;
        highestBidder = msg.sender;
        isBidder[msg.sender] = true;

        emit Bid(highestBidder, highestBid, _tokenID);
    }

    function withdraw() external {
        require(isBidder[msg.sender], "msg.sender is not a bidder!");
        require(
            msg.sender != highestBidder && msg.sender != address(0),
            "Highest bidder cannot withraw without revoking"
        );
        require(Ended, "Kindly wait for auction to finish.");
        uint256 bal = bids[msg.sender];
        delete bids[msg.sender];

        payable(msg.sender).transfer(bal);
        isBidder[msg.sender] = false;

        emit Withdrawal(msg.sender, bal);
    }

    function end(uint256 _tokenID) public {
        require(Started, "Auction has not started!");
        require(block.timestamp > EndAT, "Auction still Ongoing!");
        require(tokenIdExists[_tokenID], "TokenID isn't up for auction! ");
        Ended = true;

        if (highestBidder != address(0)) {
            nftContract.transferFrom(address(this), highestBidder, _tokenID);
            payable(seller).transfer(highestBid);
        } else {
            nftContract.transferFrom(address(this), seller, _tokenID);
        }
        emit AuctionEnded(highestBidder, seller, highestBid, _tokenID);
    }

    function revokeBid(uint256 _tokenID) public {
        require(block.timestamp < EndAT, "Auction Already Ended!");
        require(tokenIdExists[_tokenID], "TokenID isn't up for auction! ");
        require(
            msg.sender == highestBidder,
            "function reserved for highest Bidder"
        );

        uint256 bal = bids[msg.sender];
        delete bids[msg.sender];
        payable(highestBidder).transfer(bal);
        isBidder[msg.sender] = false;
        highestBidder= address(0);

        emit RevokedBid(msg.sender, bal, _tokenID);
    }
}
