// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is Pausable, Ownable {

    uint private reserveA;
    uint private reserveB;


    constructor(address initialOwner) Ownable(initialOwner) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired,
         uint amountAMin, uint amountBMin, address to, uint deadline) 
         external returns (uint amountA, uint amountB, uint liquidity){

    require(tokenA != address(0) && tokenB != address(0), "Cannot be 0 address");
        //require(amountADesired >= amountAMin || amountADesired <= reserveA, "Invalid amount to deposit in token A");
        
        uint balanceA = IERC20(tokenA).balanceOf(address(this));
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
            //calculate the reserves
        reserveA += amountADesired - amountAMin;
        reserveB += amountBDesired - amountBMin;
        
        uint amountAUnits = 0;
    }
}
