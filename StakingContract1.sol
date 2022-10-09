// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    /*
        stake tokens
        unstake tokens
        issue tokens {
            100 ETH 1:1 , for every 1 ETH, we give 1 DAPP token
            50 ETH and 50 DAI staked, we give 1 DAPP/ 1 DAI
        }
        add allowed tokens
        is token allowed?
        get ETH values
    */

    // A list/ array of allowed staking tokens
    address[] public allowedTokens;
    // An array of all stakers
    address[] public stakers;
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // to know how many different tokens an address(user) has staked
    mapping(address => uint256) public uniqueTokensStaked;
    // mapping of token address to its pricefeed address
    mapping(address => address) public tokenPriceFeedMapping;

    IERC20 public dappToken;

    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers in stakers array
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
            // send token reward
            // based on their TVL
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(
            uniqueTokensStaked[_user] > 0,
            "This user has no Tokens staked!"
        );
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            address _token = allowedTokens[allowedTokensIndex];
            totalValue = totalValue + getUserSingleTokenValue(_token, _user);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _token, address _user)
        public
        view
        returns (uint256)
    {
        // 1 ETH -> $2,000 ; 200 DAI -> $200 ... etc
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // priceFeed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), uint256(decimals));
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // how much can they stake
        require(_amount > 0, "Amount must be more than 0!");
        // is token allowed?
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        // to call the transfer from of user address on token
        // we always need the contract address and the abi
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        // To Update user balance using a mapping...
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // to push user into a stakers array
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
            // to get staker ID , create a struct with a staker ID and create a mapping of staker to ID
        }
    }

    function unstakeTokens(address _token) public {
        // to fetch the staking balance... how much of token user has??
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0 to proceed!");
        IERC20(_token).transfer(msg.sender, balance);
        // This Vulnerable to re-entrancy attacks?
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    // to know how many unique tokens a user has staked
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // function to add allowed tokens to allowed tokens array
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}
