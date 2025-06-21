// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract SimpleSwap is ERC20, ERC20Pausable, Ownable {
    constructor(address initialOwner)
        ERC20("LiquidityToken", "LTK")
        Ownable(initialOwner)
    {}

    uint256 private reserveA;
    uint256 private reserveB;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }

    /**
    *  Given some asset amount and reserves, returns an amount of the other asset representing equivalent value.
    */
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB){
        return ((amountA * reserveB) / (reserveA + amountA));
    }


    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, 
        uint amountAMin, uint amountBMin, address to, uint deadline) 
        external returns (uint amountA, uint amountB, uint liquidity){
        
        uint start = block.timestamp;
        // validacion de parametros
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");
        require((amountADesired > 0 && amountBDesired > 0 && deadline > 0 
            && amountAMin > 0 && amountBMin > 0 ),"Invalid input parameters!"); 

        (amountA, amountB) = calculateLiquidityAmounts(amountADesired, amountBDesired);
        require((amountA >= amountAMin),"Not meet the minimum for TokenA!");
        require((amountB >= amountBMin),"Not meet the minimum for TokenB!");

        // validacion disponibilidad de fondos
        require(ERC20(tokenA).balanceOf(msg.sender) >= amountA, "Insufficient TokenA funds!");
        require(ERC20(tokenB).balanceOf(msg.sender) >= amountB, "Insufficient TokenB funds!");
        
        reserveA += amountA;
        reserveB += amountB;

        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        liquidity = calculateLiquidityToken(amountA, amountB);
        this.transfer(msg.sender, liquidity);
        require(deadline > block.timestamp - start, "Deadline reached!");
        return (amountA, amountB, liquidity);
    }

    function calculateLiquidityAmounts(uint amountADesired, uint amountBDesired) internal view
        returns (uint amountA, uint amountB) {
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }
        uint amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            return (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = (amountBDesired * reserveA) / reserveB;
            return (amountAOptimal, amountBDesired);
        }
    }

    function calculateTokenAmounts(uint liquidity) internal view returns (uint256, uint256){
        return (liquidity * reserveA / this.totalSupply(), liquidity * reserveA / this.totalSupply());
    }



    function calculateLiquidityToken(uint256 amountA, uint256 amountB) internal view returns (uint256){
         if(this.totalSupply() == 0){
             return Math.sqrt(amountA * amountB);
        }else {
            return (Math.min((amountA / reserveA), (amountB / reserveB)) * this.totalSupply());
        }
    }

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin,
        address to, uint deadline) external  returns (uint amountA, uint amountB){

        uint start = block.timestamp;
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");
        require((liquidity > 0 && deadline > 0 && amountAMin > 0 && amountBMin > 0),
        "Invalid input parameters!");

        require(this.balanceOf(msg.sender) >= liquidity, "Insufficient Liquidity Tokens!");
        (amountA, amountB) = calculateTokenAmounts(liquidity);
        require((amountA >= amountAMin), "Not meet the minimum for TokenA!");
        require((amountB >= amountBMin), "Not meet the minimum for TokenB!");

        require((reserveA >= amountA), "Insufficient TokenA!");
        require((reserveB >= amountB), "Insufficient TokenB!");

        super._burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;

        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);
        require(deadline > block.timestamp - start, "Deadline reached!");
        return (amountA, amountB);
    }

     function getPrice(address tokenA, address tokenB) external view returns (uint price){
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(reserveA > 0 && reserveB > 0, "No available liquidity tokens!");
        price = (reserveB * 1e18) / reserveA;
        return price;
     }

     function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut){
        require(amountIn > 0 , "Invalid input parameters!");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
     }

     function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path,
         address to, uint deadline) external returns (uint[] memory amounts){
        
        uint start = block.timestamp;

        require(amountIn > 0 && amountOutMin > 0 && path.length == 2,"Invalid input parameters!");
        require(path[0] != address(0) && path[1] != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");

        bool isTokenA = keccak256(abi.encodePacked(ERC20(path[0]).symbol())) == keccak256(abi.encodePacked("MTKA"));

        uint amountOut = this.getAmountOut(amountIn, (isTokenA ? reserveA : reserveB), isTokenA ? reserveB : reserveA);
        require((amountOut >= amountOutMin),"Not meet the minimum!");
        require(ERC20(path[0]).balanceOf(msg.sender) >= amountIn, "Insufficient Token funds!");
        require(ERC20(path[1]).balanceOf(address(this)) >= amountOut, "Insufficient Token funds!");
        
        if(isTokenA){
            reserveA += amountIn;
            reserveB -= amountOut;
        }else{
            reserveA -= amountIn;
            reserveB += amountOut; 
        }

        ERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        ERC20(path[1]).transfer(msg.sender, amountOut);

        amounts[0] = amountIn;
        amounts[1] = amountOut;
        require(deadline > block.timestamp - start, "Deadline reached!");
        return amounts;
     }
}

