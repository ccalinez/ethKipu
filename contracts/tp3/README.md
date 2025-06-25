````markdown
# SimpleSwap

**Author:** Cristian Alinez  
**Solidity Version:** ^0.8.27  
**License:** MIT

---

## Overview

SimpleSwap is a basic Automated Market Maker (AMM) smart contract implementing liquidity pool functionality for ERC20 tokens. It allows users to add/remove liquidity and swap tokens securely using OpenZeppelin libraries for token operations, ownership, and pausability.

---

## Features

- Add liquidity by depositing TokenA and TokenB and mint liquidity tokens.
- Remove liquidity by burning liquidity tokens and withdrawing TokenA and TokenB.
- Swap exact amounts of one token for another.
- Pausable contract controlled by the owner.
- Price calculation based on current reserves.
- Safe token transfers using OpenZeppelin standards.

---

## Contract Addresses

| Contract       | Address                                     |
| -------------- | ------------------------------------------- |
| TokenA (MTKA)  | `0x1234567890abcdef1234567890abcdef12345678` |
| TokenB (MTKB)  | `0xabcdef1234567890abcdef1234567890abcdef12` |
| SimpleSwap     | `0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef` |

> **Note:** Replace the above addresses with your actual deployed contract addresses.

---

## Deployment

The contract is deployed with an initial owner address that can pause/unpause the contract and manage ownership.

```solidity
constructor(address initialOwner) 
````

---

## Usage

### Adding Liquidity

```solidity
addLiquidity(
    address tokenA, 
    address tokenB, 
    uint amountADesired, 
    uint amountBDesired, 
    uint amountAMin, 
    uint amountBMin, 
    address to, 
    uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
```

* Adds liquidity to the pool by depositing TokenA and TokenB.
* Mints liquidity tokens to the specified address `to`.
* Requires approval of token transfers beforehand.

---

### Removing Liquidity

```solidity
removeLiquidity(
    address tokenA, 
    address tokenB, 
    uint liquidity, 
    uint amountAMin, 
    uint amountBMin, 
    address to, 
    uint deadline
) external returns (uint amountA, uint amountB);
```

* Burns liquidity tokens and withdraws underlying TokenA and TokenB.
* Tokens are sent to the address `to`.

---

### Swapping Tokens

```solidity
swapExactTokensForTokens(
    uint amountIn, 
    uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline
) external returns (uint[] memory amounts);
```

* Swaps `amountIn` of one token for another, enforcing a minimum output amount (`amountOutMin`) to protect against slippage.
* `path` must be an array of length 2 with `[tokenIn, tokenOut]`.
* The swapped tokens are sent to the address `to`.

---

### Pausing / Unpausing

Only the contract owner can pause/unpause the contract.

```solidity
pause() external onlyOwner;
unpause() external onlyOwner;
```

---

## Events

* `LiquidityAdded(uint tokenAIn, uint tokenBIn, uint liquidityOut)`
* `LiquidityRemoved(uint tokenAOut, uint tokenBOut, uint liquidityIn)`
* `TokenSwapped(string tokenIn, uint amountIn, string tokenOut, uint amountOut)`

---

## Notes

* Ensure token approvals are granted to the SimpleSwap contract before calling `addLiquidity` or `swapExactTokensForTokens`.
* Deadlines are enforced to protect users from front-running and stale transactions.
* This contract currently supports only two tokens in the pool and swaps between them.

---

## License

This project is licensed under the MIT License.

---

If you have any questions or want to contribute, please reach out to Cristian Alinez.

```

