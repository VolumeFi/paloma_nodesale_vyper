# Paloma Node Sale Contract

This Vyper contract facilitates the sale of nodes in the Paloma network, allowing users to purchase nodes using either ETH or ERC20 tokens. It includes features such as referral rewards, fund withdrawal by the admin, and time-bound sale periods.

## Features

- **Token Swap**: Users can pay for nodes using any ERC20 token or ETH, which is then swapped to the contract's reward token using a specified swap router.
- **Referral Program**: The contract supports a referral program where users can earn rewards for referring others to purchase nodes.
- **Admin Controls**: Admins have the ability to update contract parameters such as the compass address, admin address, funds receiver, referral percentages, and sale start/end timestamps.
- **Event Logging**: The contract emits events for significant actions such as updates to the compass or admin, changes in referral percentages, node purchases, and fund withdrawals.

## Contract Events

- `SetPaloma`
- `UpdateCompass`
- `UpdateAdmin`
- `RewardClaimed`
- `ReferralRewardPercentagesChanged`
- `StartEndTimestampChanged`
- `RefundOccurred`
- `ReferralReward`
- `FundsWithdrawn`
- `FundsReceiverChanged`
- `Purchased`

## Interfaces

- `ISwapRouter02`: Interface for the Uniswap V2 Router used for token swaps.
- `IWETH`: Interface for wrapping and unwrapping ETH.
- `ERC20`: Standard ERC20 interface for token interactions.

## Public Variables

- `REWARD_TOKEN`, `SWAP_ROUTER_02`, `WETH9`: Addresses of the reward token, swap router, and WETH contract, respectively.
- `paloma`, `compass`, `admin`, `funds_receiver`: Addresses for contract control and fund management.
- `referral_discount_percentage`, `referral_reward_percentage`: Percentages for the referral program.
- `start_timestamp`, `end_timestamp`: Timestamps defining the sale period.

## Functions

### Admin Functions

- `update_compass`, `update_admin`, `set_paloma`, `set_funds_receiver`, `set_referral_percentages`, `set_start_end_timestamp`: Functions for updating contract parameters.

### User Functions

- `claim_referral_reward`, `add_referral_reward`, `refund`, `pay_for_token`, `pay_for_eth`: Functions for users to interact with the contract, including purchasing nodes and claiming referral rewards.

### Utility Functions

- `_paloma_check`, `_fund_receiver_check`, `_admin_check`: Internal functions for access control.

## Deployment

The contract is deployed with initial parameters for the compass address, swap router, reward token, admin address, funds receiver, and sale start/end timestamps.

## Usage

To interact with the contract, users can call the `pay_for_token` or `pay_for_eth` functions to purchase nodes. Referral rewards can be claimed through the `claim_referral_reward` function. Admins can update contract parameters and withdraw funds using their respective functions.

## Development

This contract is written in Vyper and requires a Vyper compiler for deployment. It is recommended to test thoroughly before deploying on the main network.

## License

This project is licensed under the Apache License 2.0.

# Paloma Node Sale NFT

## Overview

This project contains the smart contract for a Node Sale NFT using Vyper. The contract is designed for the Paloma blockchain and manages the sale and ownership of NFTs representing nodes in the network.

## Features

- **NFT Creation**: Allows the creation of unique NFTs representing nodes.
- **Ownership Management**: Tracks the ownership of each NFT.
- **Sale Mechanism**: Facilitates the sale of nodes through NFT transactions.

## Requirements

- Vyper: The smart contract is written in Vyper and requires the Vyper compiler for deployment.
- Ethereum Virtual Machine (EVM) Compatible Blockchain: Designed for deployment on EVM-compatible blockchains, specifically the Paloma blockchain.
