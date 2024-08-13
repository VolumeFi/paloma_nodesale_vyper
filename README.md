# PalomaNodeSale

PalomaNodeSale is a smart contract written in Vyper for managing node sales. It includes features for activating wallets, creating and removing promo codes, updating whitelist amounts, and handling node sales and redemptions.

## Contract Overview

The PalomaNodeSale contract is designed to facilitate the sale and management of nodes. It provides functionalities for:
- Activating wallets
- Creating and removing promo codes
- Updating whitelist amounts
- Handling node sales and redemptions

## Contract Functions

### `__init__`
Initializes the contract with the provided parameters.

### `activate_wallet(_paloma: bytes32)`
Activates a wallet for node sales. This function is typically called by an admin to enable a wallet to participate in node sales.

### `create_promo_code(_promo_code: bytes32, _recipient: address)`
Creates a new promo code with a specified recipient. This function allows the admin to generate promo codes that can be used to get discounts on node purchases.

### `remove_promo_code(_promo_code: bytes32)`
Removes an existing promo code. This function allows the admin to invalidate a promo code that is no longer needed or has been misused.

### `update_whitelist_amounts(_to_whitelist: address, _amount: uint256)`
Updates the whitelist amount for a specific address. This function is used to set or update the amount of nodes a particular address is allowed to purchase.

### `node_sale(_to: address, _count: uint256, _nonce: uint256)`
Handles the sale of a node. This function processes the sale and updates the state to reflect the purchase.

### `redeem_from_whitelist(_to: address, _count: uint256, _nonce: uint256)`
Handles the redemption of a node from the whitelist. This function allows a user to redeem their purchased node from the whitelist.

### `pay_for_eth(_estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256)`
Handles payment for nodes using ETH. This function processes the payment and updates the state to reflect the purchase.

### `pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256)`
Handles payment for nodes using a specified token. This function processes the payment and updates the state to reflect the purchase.

### `claim()`
Allows users to claim their rewards. This function transfers the claimable amount to the user.

### `set_fee_receiver(_new_fee_receiver: address)`
Sets a new fee receiver. This function allows the admin to update the address that receives the fees.

### `set_funds_receiver(_new_funds_receiver: address)`
Sets a new funds receiver. This function allows the admin to update the address that receives the funds.

### `set_paloma(_new_paloma: bytes32)`
Sets a new Paloma identifier. This function allows the admin to update the Paloma identifier.

### `set_processing_fee(_new_processing_fee: uint256, _new_subscription_fee: uint256)`
Sets new processing and subscription fees. This function allows the admin to update the fees.

### `set_referral_percentages(_new_referral_discount_percentage: uint256, _new_referral_reward_percentage: uint256, _new_slippage_fee_percentage: uint256)`
Sets new referral and slippage fee percentages. This function allows the admin to update the percentages.

### `set_start_end_timestamp(_new_start_timestamp: uint256, _new_end_timestamp: uint256)`
Sets new start and end timestamps. This function allows the admin to update the sale period.

### `update_admin(_new_admin: address)`
Updates the admin address. This function allows the current admin to transfer admin rights to a new address.

### `update_compass(_new_compass: address)`
Updates the compass address. This function allows the admin to update the compass contract address.

### `__default__()`
Fallback function to accept ETH.

## Usage

### Deploying the Contract

To deploy the contract, use the `ape` CLI or your preferred deployment tool. Ensure you have the necessary accounts and parameters set up.

```bash
ape run deploy