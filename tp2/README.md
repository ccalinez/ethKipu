# Auction Contract – Module 2 Final Project

## 🧾 Description

This smart contract implements a simple **auction system** on Ethereum. Bidders can submit offers that must be at least **5% higher** than the current highest bid. The contract handles:

- Auction initialization and closure
- Bid validation and recording
- Winner selection
- Refunds for non-winning bidders (minus a 2% commission)

---

## 👨‍💻 Author

**Cristian Alinez**

---

## ⚙️ Requirements

- Solidity version `>=0.8.7`
- Compatible with Remix, Hardhat, or Truffle environments

---

## 🧩 Structs and Enums

### Structs

- `Bid`: Represents a bid submitted by a bidder (includes timestamp, amount, accumulated value, etc.)

### Enums

- `Stage`: Represents the auction stage — `TakingBid` or `Finished`
- `Rol`: Represents the user roles — `Admin` or `Bidder`

---

## 🚀 Functions

### 📤 `bid()`

Places a new bid.  
✅ The new bid must be **at least 5% higher** than the previous highest bid.  
🔁 Tracks the bidder in a list and updates their accumulated balance.

---

### 💰 `withdrawal()`

Allows a bidder to withdraw the **surplus** (amount beyond the last highest bid).  
🔐 Only available during the auction.  
❌ Reverts if no withdrawable funds are present.

---

### 🔒 `close()`

Closes the auction.  
- Declares a winner if a valid bid exists
- Refunds all losing bidders minus a **2% commission**
- Only the `Admin` can call this function

---

### 🏆 `showWinner() → (address, uint)`

Returns the address and amount of the winning bidder.  
❌ Reverts if no bids were placed.

---

### 📜 `showBids() → Bid[]`

Returns all the bids placed during the auction.  
📊 Useful for external inspection or displaying history.

---

## 🛠️ Internal Utilities

### `nextStage()`

Moves the auction to the next stage.

### Modifiers

- `only(Rol role)`: Restricts function access to either `Admin` or `Bidder`
- `atStage(Stage)`: Ensures functions are only callable during allowed stages
- `timedTransitions()`: Automatically transitions the auction stage after time limit

---

## 📦 Events

- `NewBid(address bidder, uint amount)`: Emitted when a new bid is placed
- `AuctionOpened(string item, uint base)`: Emitted when the auction starts
- `AuctionFinished(string item, address winner, uint amount)`: Emitted when the auction ends

---

## ⚠️ Custom Errors

- `NotEnoughHigh(string)`: Bid is not 5% higher than the current highest
- `NothingToWithdraw()`: No excess funds to withdraw
- `AccessNotAllowed(string)`: Sender lacks the required role
- `NotAllowedAtStage(Stage)`: Function called at an invalid stage
- `NotWinningBid()`: No winning bid present

---

## 🧪 Usage Example in Remix

1. **Deploy** the contract with:
   - `duration` (in seconds)
   - `base` (base bid in ETH)
   - `item` (item name)
2. **Call `bid()`**, sending ETH with the transaction
3. **Call `withdrawal()`** to retrieve any surplus funds (if applicable)
4. After time expires, **call `close()`** as the admin
5. Retrieve winner info using **`showWinner()`**


## 🪙 License

[MIT](https://opensource.org/licenses/MIT)
