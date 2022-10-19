// SPDX-License-Identifier: MIT

/*
1.1 - These state variables helps to internally keep track of the tokens 
    (token0 and token1) in the contract to avoid user manipulation using 
    balanceOf(token).

1.2 - _tokenIn == address(token0)
            ? token0.transferFrom(msg.sender, address(this), amountIn)
            : token1.transferFrom(msg.sender, address(this), amountIn);

1.3 - a = dx = amount of token in 
        dy = amount of token out
        L = total liquidity (reserve0 + reserve1)
        T = total supply
        s = shares to mint
*/

pragma solidity ^0.8.0;
import "../IERC20.sol";

contract CSAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0; // -- 1.1
    uint256 public reserve1;

    uint256 public TotalSupply;
    mapping(address => uint256) public balanceOf;

    event Mint(address indexed To, uint256 Shares);
    event Burn(address indexed From, uint256 Shares);
    event Swap(
        address indexed User,
        address TokenIn,
        uint256 amountIn,
        uint256 amountOut
    );
    event AddLiquidity(
        address indexed LP,
        uint256 amount0In,
        uint256 amount1In
    );
    event RemoveLiquidity(
        address indexed LP,
        uint256 amount0Out,
        uint256 amount1Out
    );

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        TotalSupply += _amount;
        emit Mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        TotalSupply -= _amount;
        emit Burn(_from, _amount);
    }

    function _updateReserves(uint256 _res0, uint256 _res1) private {
        reserve0 = _res0;
        reserve1 = _res1;
    }

    function swap(address _tokenIn, uint256 _amountIn)
        external
        returns (uint256 amountOut)
    {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Unsupported token"
        );

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 resIn, uint256 resOut) = isToken0 // we initialise local variables.
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        // Transfer token in -- 1.2

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint256 amountIn = tokenIn.balanceOf(address(this)) - resIn; // - to calculate amountIn

        // calculate amount out (include fees (0.3%))
        // dx = dy -- 1.3
        amountOut = (amountIn * 997) / 1000;

        // update reserve state variables

        (uint256 res0, uint256 res1) = isToken0
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);

        _updateReserves(res0, res1);

        // Transfer token out
        tokenOut.transfer(msg.sender, amountOut);
        emit Swap(msg.sender, _tokenIn, amountIn, amountOut);
    }

    function addLiquidity(uint256 _amount0, uint256 _amount1)
        external
        returns (uint256 shares)
    {
        require(
            _amount0 > 0 && _amount1 > 0,
            "Amounts provided cannot be Zero."
        );
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        uint256 amount0In = bal0 - reserve0; // - to calculate amountIn
        uint256 amount1In = bal1 - reserve1;

        /*
         calculate shares to mint -- 1.3
         (L + a)/ L = (T + s) / T

         s = (a * T) / L
        */
        if (TotalSupply == 0) {
            shares = (amount0In + amount1In);
        } else {
            shares =
                ((amount0In + amount1In) * TotalSupply) /
                (reserve0 + reserve1);
        }
        require(shares > 0, "Shares  = 0");
        mint(msg.sender, shares);
        _updateReserves(bal0, bal1);
        emit AddLiquidity(msg.sender, amount0In, amount1In);
    }

    function removeLiquidity(uint256 _shares)
        external
        returns (uint256 amount0Out, uint256 amount1Out)
    {
        /*
         calculate tokens to burn -- 1.4
          a / L = s / T

         a = (L * s ) / T
         a = ((reserve0 + reserve1) * shares) / Total shares
        */

        amount0Out = (reserve0 * _shares) / TotalSupply;
        amount1Out = (reserve1 * _shares) / TotalSupply;
        burn(msg.sender, _shares);
        _updateReserves(reserve0 - amount0Out, reserve1 - amount1Out);
        if (amount0Out > 0) {
            token0.transfer(msg.sender, amount0Out);
        }

        if (amount1Out > 0) {
            token1.transfer(msg.sender, amount1Out);
        }

        emit RemoveLiquidity(msg.sender, amount0Out, amount1Out);
    }

    function getReserves()
        external
        view
        returns (
            uint112 reserve0Value,
            uint112 reserve1Value,
            uint32 blockTimestampLast
        )
    {
        blockTimestampLast = uint32(block.timestamp);
        reserve0Value = uint112(reserve0);
        reserve1Value = uint112(reserve1);
    }
}

/*

1.4 -   a = dx = amount of token out 
        dy = amount of token out
        L = total liquidity (reserve0 + reserve1)
        T = total supply
        s = shares to mint

// To Aid readability lol.

            REFACTORING FUNCTION SWAP TO BE MORE GAS EFFICIENT! (OLD CODE)...
function swap(address _tokenIn, uint256 _amountIn)
        external
        returns (uint256 amountOut)
    {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Unsupported token"
        );

        // Transfer token in -- 1.2
        uint256 amountIn;
        if (_tokenIn == address(token0)) {
            token0.transferFrom(msg.sender, address(this), _amountIn);
            amountIn = token0.balanceOf(address(this)) - reserve0; // - to calculate amountIn
        } else {
            token1.transferFrom(msg.sender, address(this), _amountIn);
            amountIn = token1.balanceOf(address(this)) - reserve1;
        }

        // calculate amount out (include fees (0.3%))
        // dx = dy -- 1.3
        amountOut = (amountIn * 997) / 1000;
        // update reserve state variables
        _tokenIn == address(token0)
            ? _updateReserves(reserve0 + amountIn, reserve1 - amountOut)
            : _updateReserves(reserve0 - amountOut, reserve1 + amountIn);
        // Transfer token out
        _tokenIn == address(token0)
            ? token1.transfer(msg.sender, amountOut)
            : token0.transfer(msg.sender, amountOut);
    }


*/
