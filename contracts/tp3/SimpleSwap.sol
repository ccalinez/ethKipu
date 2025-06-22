// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

 /**
 * @title SimpleSwap Contract
 * @author Cristian Alinez
 * @notice A basic automated market maker (AMM) implementing liquidity pool functionality for ERC20 tokens
 * @dev Uses OpenZeppelin libraries for secure token operations, pausing, and ownership management
 */
contract SimpleSwap is ERC20, ERC20Pausable, Ownable {

    // @notice Reserve of TokenA in the pool
    uint256  private reserveA;
    // @notice Reserve of TokenB in the pool
    uint256  private reserveB;

    /**
     * @notice Constructor to initialize the contract with an owner
     * @param initialOwner The address of the initial owner of the contract
     * @dev Initializes ERC20 token with name "LiquidityToken" and symbol "LTK"
     */
    constructor(address initialOwner)
        ERC20("LiquidityToken", "LTK")
        Ownable(initialOwner){}

    /**
     * @notice Pauses the contract, restricting certain functions
     * @dev Only callable by the owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Only callable by the owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Adds liquidity to the pool
     * @dev Transfers tokenA and tokenB from sender and mints liquidity tokens based on the input and reserves
     * @param tokenA Address of the tokenA
     * @param tokenB Address of the tokenB
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add
     * @param amountBMin Minimum amount of tokenB to add
     * @param to Recipient address of the liquidity tokens
     * @param deadline Deadline timestamp by which transaction must be completed
     * @return amountA Amount of tokenA actually added
     * @return amountB Amount of tokenB actually added
     * @return liquidity Amount of liquidity tokens minted
     */
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, 
        uint amountBDesired, uint amountAMin, uint amountBMin,
        address to, uint deadline) 
        external  whenNotPaused
        returns (uint amountA, uint amountB, uint liquidity){
    
        uint start = block.timestamp;
        //Check input
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");
        require((amountADesired > 0 && amountBDesired > 0 && deadline > 0 
            && amountAMin > 0 && amountBMin > 0 ),"Invalid input parameters!"); 
        // Calculate optimal amounts based on current reserves
        (amountA, amountB) = calculateLiquidityAmounts(amountADesired, amountBDesired);
        // Ensure minimums are met
        require((amountA >= amountAMin),"Not meet the minimum for TokenA!");
        require((amountB >= amountBMin),"Not meet the minimum for TokenB!");
        // Check sender's balance
        require(ERC20(tokenA).balanceOf(msg.sender) >= amountA, "Insufficient TokenA funds!");
        require(ERC20(tokenB).balanceOf(msg.sender) >= amountB, "Insufficient TokenB funds!");
        // Transfer tokens from sender to contract
        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        // Calculate liquidity tokens to mint
        liquidity = calculateLiquidityToken(amountA, amountB);
        reserveA += amountA;
        reserveB += amountB;
        super._mint(to, liquidity);
        require(deadline > block.timestamp - start, "Deadline reached!");
        return (amountA, amountB, liquidity);
    }

    /**
     * @notice Removes liquidity from the pool, returning tokens to the user
     * @dev Burns liquidity tokens and transfers tokenA and tokenB to user
     * @param tokenA Address of tokenA
     * @param tokenB Address of tokenB
     * @param liquidity Amount of liquidity tokens to burn
     * @param amountAMin Minimum amount of tokenA to withdraw
     * @param amountBMin Minimum amount of tokenB to withdraw
     * @param to Address to send the withdrawn tokens
     * @param deadline Deadline timestamp by which the transaction must be completed
     * @return amountA The amount of tokenA withdrawn
     * @return amountB The amount of tokenB withdrawn
     */
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin,
        uint amountBMin, address to, uint deadline) 
        external whenNotPaused 
        returns (uint amountA, uint amountB){

        uint start = block.timestamp;
        // Check inputs
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");
        require((liquidity > 0 && deadline > 0 && amountAMin >= 0 && amountBMin >= 0),
        "Invalid input parameters!");

        require(this.balanceOf(msg.sender) >= liquidity, "Insufficient Liquidity Tokens!");
        // Calculate token amounts based on liquidity tokens
        (amountA, amountB) = calculateTokenAmounts(liquidity);
        // Check minimum amounts
        require((amountA >= amountAMin), "Not meet the minimum for TokenA!");
        require((amountB >= amountBMin), "Not meet the minimum for TokenB!");
        // Check that there are reserves to cover transfers 
        require((reserveA >= amountA), "Insufficient TokenA!");
        require((reserveB >= amountB), "Insufficient TokenB!");
        // Burn liquidity tokens
        super._burn(msg.sender, liquidity);
        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;
        // Transfer tokens to user
        ERC20(tokenA).transfer(to, amountA);
        ERC20(tokenB).transfer(to, amountB);
        require(deadline > block.timestamp - start, "Deadline reached!");
        return (amountA, amountB);
    }

    /**
     * @notice Returns the price of tokenA in terms of tokenB based on current reserves
     * @dev The price is scaled by 1e18 for precision
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     * @return price The calculated price (tokenB/tokenA * 1e18)
     */
     function getPrice(address tokenA, address tokenB) 
        external view 
        returns (uint price){
        require(tokenA != address(0) && tokenB != address(0), "Invalid token addresses!");
        require(reserveA > 0 && reserveB > 0, "No available liquidity tokens!");
        price = (reserveB * 1e18) / reserveA;
        return price;
     }

    /**
     * @notice Calculates the amount of output tokens that will be received given an input amount and reserves
     * @dev Uses a constant product formula without fees
     * @param amountIn Amount of input tokens
     * @param reserveIn Current reserve of the input token
     * @param reserveOut Current reserve of the output token
     * @return amountOut The amount of output tokens the user would receive
     */
     function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) 
        external pure 
        returns (uint amountOut){
        require(amountIn > 0 , "Invalid input parameters!");
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        return amountOut;
     }

    /**
     * @notice Swaps an exact amount of one token for another
     * @dev Currently only supports swaps between two tokens using predefined reserves. No slippage protection other than `amountOutMin`.
     * @param amountIn Exact amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of two token addresses [tokenIn, tokenOut]
     * @param to Address to receive the output tokens
     * @param deadline Timestamp by which the transaction must be mined
     * @return amounts Array containing [amountIn, amountOut]
     */
     function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path,
         address to, uint deadline) 
         external whenNotPaused
         returns (uint[] memory amounts){
        
        uint start = block.timestamp;
        // Check inputs
        require(amountIn > 0 && amountOutMin > 0 && path.length == 2,"Invalid input parameters!");
        require(path[0] != address(0) && path[1] != address(0), "Invalid token addresses!");
        require(to != address(0), "Invalid recipient address");
        // Determine the type of token you want to exchange A or B
        bool isTokenA = keccak256(abi.encodePacked(ERC20(path[0]).symbol())) == keccak256(abi.encodePacked("MTKA"));
        // Calculate the amount of tokens that will be delivered
        uint amountOut = this.getAmountOut(amountIn, (isTokenA ? reserveA : reserveB), (isTokenA ? reserveB : reserveA));
        require((amountOut >= amountOutMin),"Not meet the minimum!");
        // Check for sufficient balances
        require(ERC20(path[0]).balanceOf(msg.sender) >= amountIn, "Insufficient Token IN funds!");
        require(ERC20(path[1]).balanceOf(address(this)) >= amountOut, "Insufficient Token OUT funds!");
        // Update reserves
        if(isTokenA){
            reserveA += amountIn;
            reserveB -= amountOut;
        }else{
            reserveA -= amountIn;
            reserveB += amountOut; 
        }
        // Transter tokens
        ERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        ERC20(path[1]).transfer(msg.sender, amountOut);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        require(deadline > block.timestamp - start, "Deadline reached!");
        return amounts;
     }

     /**
     * @notice Internal function to update balances after token transfer
     * @dev Overrides _update from ERC20 and ERC20Pausable to support pausable token transfers
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param value Number of tokens transferred
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable){
        super._update(from, to, value);
    }

    /**
     * @notice Calculates optimal token amounts for liquidity addition based on current reserves
     * @dev Ensures pool ratio is maintained by minimizing excess deposits
     * @param amountADesired The amount of tokenA desired to deposit
     * @param amountBDesired The amount of tokenB desired to deposit
     * @return amountA The calculated amount of tokenA to deposit
     * @return amountB The calculated amount of tokenB to deposit
     */
    function calculateLiquidityAmounts(uint amountADesired, uint amountBDesired) 
        internal view
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

    /**
     * @notice Calculates token amounts corresponding to a specific amount of liquidity tokens
     * @dev Uses current reserves and total supply to calculate proportional amounts
     * @param liquidity The amount of liquidity tokens to convert
     * @return amountA The amount of tokenA corresponding to the liquidity tokens
     * @return amountB The amount of tokenB corresponding to the liquidity tokens
     */
    function calculateTokenAmounts(uint liquidity) 
        internal view 
        returns (uint256, uint256){
        return ((liquidity * reserveA / this.totalSupply()), (liquidity * reserveB / this.totalSupply()));
    }

    /**
     * @notice Calculates the amount of liquidity tokens to mint based on deposited token amounts
     * @dev Uses the square root of the product if first time, else proportional to reserves
     * @param amountA The amount of tokenA to deposit
     * @param amountB The amount of tokenB to deposit
     * @return liquidity The amount of liquidity tokens to mint
     */
    function calculateLiquidityToken(uint256 amountA, uint256 amountB) 
        internal view 
        returns (uint256){

         if(this.totalSupply() == 0){
             return Math.sqrt(amountA * amountB);
        }else {
            uint liquidityA = (amountA * totalSupply()) / reserveA;
            uint liquidityB = (amountB * totalSupply()) / reserveB;
            return Math.min(liquidityA, liquidityB);
        }
    }

    
}

