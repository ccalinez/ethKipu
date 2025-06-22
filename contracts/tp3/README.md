# SimpleSwap Smart Contract

## Overview

**SimpleSwap** is a basic Automated Market Maker (AMM) implemented in Solidity for handling ERC20 token swaps and liquidity provisioning. It supports operations like adding/removing liquidity, token swaps, and price retrievals, while leveraging OpenZeppelin's secure contract libraries.

## Features

- ERC20-based Liquidity Token (`LTK`)
- Liquidity pool management for two ERC20 tokens
- Token swap using constant product formula
- Pausable contract functionality for emergency control
- Ownership control using OpenZeppelin's `Ownable`

## Contract Details

- Token Name: `LiquidityToken`
- Token Symbol: `LTK`
- Author: Cristian Alinez
- Solidity Version: ^0.8.27
- License: MIT

## Functions

### Owner-Only

- `pause()` – Pauses the contract.
- `unpause()` – Unpauses the contract.

### Liquidity Management

- `addLiquidity(...)` – Adds liquidity to the pool and mints LTK.
- `removeLiquidity(...)` – Removes liquidity and returns underlying tokens.

### Swapping

- `swapExactTokensForTokens(...)` – Swaps a specified amount of one token for another.

### Utility

- `getPrice(...)` – Returns tokenA/tokenB price based on reserves.
- `getAmountOut(...)` – Calculates output token amount for a given input using reserves.

## Internal Calculations

- `calculateLiquidityAmounts(...)` – Optimal deposit amounts based on reserve ratios.
- `calculateTokenAmounts(...)` – Converts LTK to tokenA/tokenB amounts.
- `calculateLiquidityToken(...)` – Mints appropriate amount of LTK based on deposits.

## Dependencies

- OpenZeppelin Contracts v5+:
  - ERC20
  - ERC20Pausable
  - Ownable
  - Math

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).