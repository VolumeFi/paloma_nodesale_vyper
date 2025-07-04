# PalomaNodeSale Smart Contract System

A comprehensive Vyper-based smart contract system for managing node sales across multiple blockchain networks. This system includes referral mechanisms, promo codes, whitelist management, and multi-chain deployment capabilities.

## System Architecture

The system consists of three main contracts:

1. **PalomaNodeSale.vy** - Core contract handling node sales, payments, and referral logic
2. **Factory.vy** - Factory contract for creating and managing FiatBot instances
3. **FiatBot.vy** - Proxy contract for handling fiat payments and wallet activation

## Contract Overview

### PalomaNodeSale Contract

The main contract that handles all node sale operations, including:
- Wallet activation and Paloma address management
- Promo code creation and management
- Payment processing (ETH and ERC20 tokens)
- Referral reward distribution
- Whitelist management
- Fee collection and distribution

### Factory Contract

A factory contract that:
- Creates FiatBot instances for users
- Manages bot deployments
- Handles cross-chain operations
- Provides proxy functionality for payments

### FiatBot Contract

A lightweight proxy contract that:
- Interfaces with the main PalomaNodeSale contract
- Handles fiat payment processing
- Manages wallet activation
- Provides refund functionality

## Detailed Function Documentation

### PalomaNodeSale Contract Functions

#### Constructor (`__init__`)
**Purpose**: Initializes the contract with all necessary parameters and addresses.

**Parameters**:
- `_compass`: Address of the compass contract (cross-chain bridge)
- `_swap_router`: Address of the Uniswap V3 swap router
- `_reward_token`: Address of the reward token (USDC)
- `_admin`: Admin address with privileged functions
- `_fund_receiver`: Address that receives sale proceeds
- `_fee_receiver`: Address that receives fees
- `_start_timestamp`: Sale start time
- `_end_timestamp`: Sale end time
- `_processing_fee`: Processing fee in reward token units
- `_subscription_fee`: Monthly subscription fee
- `_slippage_fee_percentage`: Slippage fee percentage (basis points)
- `_parent_fee_percentage`: Parent referral fee percentage
- `_default_discount_percentage`: Default discount percentage
- `_default_reward_percentage`: Default reward percentage
- `_grains_per_node`: Grains allocated per node
- `_v1_contract`: Address of the V1 contract for backward compatibility

**Security Considerations**:
- All addresses are validated to be non-zero
- Timestamps must be valid
- Percentages are bounded to prevent excessive fees
- Immutable addresses prevent post-deployment changes

**Example Usage**:
```python
# Deploy with specific parameters
paloma_sale = deployer.deploy(
    project.PalomaNodeSale,
    compass_address,
    swap_router_address,
    usdc_address,
    admin_address,
    fund_receiver_address,
    fee_receiver_address,
    start_timestamp,
    end_timestamp,
    processing_fee,
    subscription_fee,
    slippage_fee_percentage,
    parent_fee_percentage,
    default_discount_percentage,
    default_reward_percentage,
    grains_per_node,
    v1_contract_address
)
```

#### `activate_wallet(_paloma: bytes32, _purchased_in_v1: bool)`
**Purpose**: Activates a wallet for node purchases by associating it with a Paloma address.

**Parameters**:
- `_paloma`: 32-byte Paloma identifier
- `_purchased_in_v1`: Boolean indicating if user purchased in V1 contract

**Access Control**: Public (anyone can activate their own wallet)

**Security Checks**:
- Validates Paloma address is not empty
- Ensures Paloma address hasn't been used before
- Checks V1 contract history to prevent duplicate activations
- Calls V1 contract if user purchased there previously

**State Changes**:
- Sets `activates[msg.sender] = _paloma`
- Emits `Activated` event

**Example Usage**:
```python
# Activate wallet with Paloma address
paloma_id = b'\x01' * 32
paloma_sale.activate_wallet(paloma_id, False, sender=user)
```

#### `create_promo_code(_promo_code: bytes32, _recipient: address, _parent_promo_code: bytes32, _referral_discount_percentage: uint256, _referral_reward_percentage: uint256)`
**Purpose**: Creates a new promo code with referral parameters (admin-only).

**Parameters**:
- `_promo_code`: 32-byte promo code identifier
- `_recipient`: Address that receives referral rewards
- `_parent_promo_code`: Parent promo code for multi-level referrals
- `_referral_discount_percentage`: Discount percentage for users (basis points)
- `_referral_reward_percentage`: Reward percentage for referrer (basis points)

**Access Control**: Admin only

**Security Checks**:
- Validates recipient is not zero address
- Ensures promo code is not empty
- Bounds percentages to prevent excessive values (max 99%)
- Ensures reward percentage is greater than 2x parent fee percentage

**State Changes**:
- Creates new PromoCode struct in storage
- Emits `PromoCodeCreated` event

**Example Usage**:
```python
# Create promo code with 5% discount and 10% reward
promo_code = b'\x01' * 32
parent_code = b'\x00' * 32
paloma_sale.create_promo_code(
    promo_code, 
    recipient_address, 
    parent_code, 
    500,  # 5% discount
    1000, # 10% reward
    sender=admin
)
```

#### `create_promo_code_by_chain(_promo_code: bytes32, _recipient: address, _parent_promo_code: bytes32, _referral_discount_percentage: uint256, _referral_reward_percentage: uint256)`
**Purpose**: Creates promo codes via cross-chain bridge (Paloma-only).

**Access Control**: Paloma bridge only

**Security**: Same validation as `create_promo_code` but with Paloma authentication

#### `remove_promo_code(_promo_code: bytes32)`
**Purpose**: Deactivates a promo code (admin-only).

**Parameters**:
- `_promo_code`: 32-byte promo code to remove

**Access Control**: Admin only

**Security Checks**:
- Validates promo code exists
- Sets active flag to false (soft delete)

**State Changes**:
- Sets `promo_codes[_promo_code].active = False`
- Emits `PromoCodeRemoved` event

#### `remove_promo_code_by_chain(_promo_code: bytes32)`
**Purpose**: Removes promo codes via cross-chain bridge (Paloma-only).

**Access Control**: Paloma bridge only

#### `update_whitelist_amounts(_to_whitelist: address, _amount: uint256)`
**Purpose**: Sets or updates whitelist allocation for an address (admin-only).

**Parameters**:
- `_to_whitelist`: Address to whitelist
- `_amount`: Number of nodes allowed to purchase

**Access Control**: Admin only

**State Changes**:
- Sets `whitelist_amounts[_to_whitelist] = _amount`
- Emits `WhitelistAmountUpdated` event

#### `refund_pending_amount(_to: address)`
**Purpose**: Refunds pending referral rewards to a user (admin-only).

**Parameters**:
- `_to`: Address to refund

**Access Control**: Admin only

**Security Checks**:
- Validates address is not zero
- Processes all pending amounts (recipient, parent1, parent2)

**State Changes**:
- Transfers pending amounts to user
- Clears pending state variables
- Emits transfer events

#### `node_sale(_to: address, _count: uint256, _nonce: uint256, _paloma: bytes32)`
**Purpose**: Processes a node sale via cross-chain bridge (Paloma-only).

**Parameters**:
- `_to`: Buyer address
- `_count`: Number of nodes to sell
- `_nonce`: Unique transaction identifier
- `_paloma`: Paloma identifier

**Access Control**: Paloma bridge only

**Security Checks**:
- Validates all parameters are non-zero
- Ensures nonce hasn't been used
- Verifies Paloma address is valid

**State Changes**:
- Records nonce usage
- Calculates grain amount
- Emits `NodeSold` event
- Calls compass contract

#### `redeem_from_whitelist(_to: address, _count: uint256, _nonce: uint256, _paloma: bytes32)`
**Purpose**: Redeems nodes from whitelist allocation (Paloma-only).

**Parameters**:
- `_to`: Redeemer address
- `_count`: Number of nodes to redeem
- `_nonce`: Unique transaction identifier
- `_paloma`: Paloma identifier

**Access Control**: Paloma bridge only

**Security Checks**:
- Validates all parameters
- Ensures sufficient whitelist allocation
- Prevents nonce reuse

**State Changes**:
- Reduces whitelist allocation
- Records nonce usage
- Emits `NodeSold` event

#### `update_paloma_history(_to: address)`
**Purpose**: Updates Paloma history and processes pending rewards (Paloma-only).

**Parameters**:
- `_to`: Address to update

**Access Control**: Paloma bridge only

**Security Checks**:
- Validates address is activated
- Ensures Paloma hasn't been used before

**State Changes**:
- Marks Paloma as used
- Transfers pending rewards to claimable
- Clears pending state
- Emits `PalomaAddressUpdated` event

#### `sync_paloma_history(_paloma: bytes32)`
**Purpose**: Syncs Paloma history from other chains (Paloma-only).

**Parameters**:
- `_paloma`: Paloma identifier to sync

**Access Control**: Paloma bridge only

**State Changes**:
- Marks Paloma as used
- Emits `PalomaAddressSynced` event

#### `pay_for_eth(_estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32)`
**Purpose**: Processes ETH payment for node purchases.

**Parameters**:
- `_estimated_node_count`: Expected number of nodes
- `_total_cost`: Total cost in reward tokens
- `_promo_code`: Promo code to use
- `_path`: Uniswap swap path
- `_enhanced`: Whether enhanced features are enabled
- `_subscription_month`: Number of subscription months
- `_own_promo_code`: User's own promo code

**Access Control**: Public (payable)

**Security Checks**:
- Validates sale period is active
- Ensures all parameters are positive
- Validates promo code exists
- Calculates and applies fees
- Handles slippage protection

**State Changes**:
- Swaps ETH to reward tokens
- Distributes funds to receivers
- Processes referral rewards
- Updates subscription if enhanced
- Refunds excess ETH

**Example Usage**:
```python
# Pay with ETH for 1 node
paloma_sale.pay_for_eth(
    1,  # node count
    10000000,  # total cost (10 USDC)
    promo_code,
    swap_path,
    False,  # not enhanced
    0,  # no subscription
    own_promo_code,
    value=eth_amount,
    sender=user
)
```

#### `pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32)`
**Purpose**: Processes ERC20 token payment for node purchases.

**Parameters**:
- `_token_in`: Token address to pay with
- `_estimated_amount_in`: Estimated token amount
- `_estimated_node_count`: Expected number of nodes
- `_total_cost`: Total cost in reward tokens
- `_promo_code`: Promo code to use
- `_path`: Uniswap swap path
- `_enhanced`: Whether enhanced features are enabled
- `_subscription_month`: Number of subscription months
- `_own_promo_code`: User's own promo code

**Access Control**: Public

**Security Checks**:
- Same as `pay_for_eth` plus token approval validation
- Handles direct USDC payments without swap

**State Changes**:
- Transfers tokens from user
- Swaps to reward tokens if needed
- Distributes funds and processes rewards
- Refunds excess tokens

#### `claim()`
**Purpose**: Allows users to claim their accumulated referral rewards.

**Access Control**: Public

**Security Checks**:
- Ensures user has claimable rewards

**State Changes**:
- Transfers claimable amount to user
- Resets claimable balance to zero
- Emits `Claimed` event

#### `set_fee_receiver(_new_fee_receiver: address)`
**Purpose**: Updates fee receiver address (admin-only).

**Parameters**:
- `_new_fee_receiver`: New fee receiver address

**Access Control**: Admin only

**Security Checks**:
- Validates address is not zero

**State Changes**:
- Updates `fee_receiver`
- Emits `FeeReceiverChanged` event

#### `set_funds_receiver(_new_funds_receiver: address)`
**Purpose**: Updates funds receiver address (admin-only).

**Parameters**:
- `_new_funds_receiver`: New funds receiver address

**Access Control**: Admin only

**Security Checks**:
- Validates address is not zero

**State Changes**:
- Updates `funds_receiver`
- Emits `FundsReceiverChanged` event

#### `set_paloma()`
**Purpose**: Sets Paloma identifier (compass-only).

**Access Control**: Compass contract only

**Security Checks**:
- Validates caller is compass
- Ensures Paloma not already set
- Validates data length

**State Changes**:
- Sets `paloma` identifier
- Emits `SetPaloma` event

#### `set_processing_fee(_new_processing_fee: uint256, _new_subscription_fee: uint256)`
**Purpose**: Updates processing and subscription fees (admin-only).

**Parameters**:
- `_new_processing_fee`: New processing fee
- `_new_subscription_fee`: New subscription fee

**Access Control**: Admin only

**State Changes**:
- Updates both fee variables
- Emits `FeeChanged` event

#### `set_slippage_fee_percentage(_new_slippage_fee_percentage: uint256)`
**Purpose**: Updates slippage fee percentage (admin-only).

**Parameters**:
- `_new_slippage_fee_percentage`: New percentage (basis points)

**Access Control**: Admin only

**Security Checks**:
- Bounds percentage to 0-99%

**State Changes**:
- Updates `slippage_fee_percentage`
- Emits `SlippageFeePercentageChanged` event

#### `set_discount_reward_percentage(_new_default_discount_percentage: uint256, _new_default_reward_percentage: uint256)`
**Purpose**: Updates default discount and reward percentages (admin-only).

**Parameters**:
- `_new_default_discount_percentage`: New discount percentage
- `_new_default_reward_percentage`: New reward percentage

**Access Control**: Admin only

**Security Checks**:
- Bounds both percentages to 0-99%

**State Changes**:
- Updates both percentage variables
- Emits `DefaultDiscountRewardPercentageChanged` event

#### `set_parent_fee_percentage(_new_parent_fee_percentage: uint256)`
**Purpose**: Updates parent fee percentage (admin-only).

**Parameters**:
- `_new_parent_fee_percentage`: New parent fee percentage

**Access Control**: Admin only

**Security Checks**:
- Bounds percentage to 0-99%

**State Changes**:
- Updates `parent_fee_percentage`
- Emits `ParentFeePercentageChanged` event

#### `set_start_end_timestamp(_new_start_timestamp: uint256, _new_end_timestamp: uint256)`
**Purpose**: Updates sale start and end timestamps (admin-only).

**Parameters**:
- `_new_start_timestamp`: New start timestamp
- `_new_end_timestamp`: New end timestamp

**Access Control**: Admin only

**Security Checks**:
- Validates both timestamps are positive

**State Changes**:
- Updates both timestamp variables
- Emits `StartEndTimestampChanged` event

#### `update_grain_amount(_new_amount: uint256)`
**Purpose**: Updates grains per node allocation (admin-only).

**Parameters**:
- `_new_amount`: New grains per node

**Access Control**: Admin only

**Security Checks**:
- Validates amount is positive

**State Changes**:
- Updates `grains_per_node`
- Emits `GrainAmountUpdated` event

#### `update_admin(_new_admin: address)`
**Purpose**: Transfers admin privileges (admin-only).

**Parameters**:
- `_new_admin`: New admin address

**Access Control**: Current admin only

**State Changes**:
- Updates `admin`
- Emits `UpdateAdmin` event

#### `update_compass(_new_compass: address)`
**Purpose**: Updates compass contract address (compass-only).

**Parameters**:
- `_new_compass`: New compass address

**Access Control**: Current compass contract only

**Security Checks**:
- Validates SLC switch is off
- Ensures new address is not zero

**State Changes**:
- Updates `compass`
- Emits `UpdateCompass` event

### Factory Contract Functions

#### Constructor (`__init__`)
**Purpose**: Initializes factory with blueprint, compass, and nodesale addresses.

**Parameters**:
- `_blueprint`: FiatBot blueprint address
- `_compass`: Compass contract address
- `_nodesale`: PalomaNodeSale contract address

#### `update_blueprint(_new_blueprint: address)`
**Purpose**: Updates blueprint address (Paloma-only).

**Access Control**: Paloma bridge only

#### `update_compass(_new_compass: address)`
**Purpose**: Updates compass address (compass-only).

**Access Control**: Current compass only

#### `update_nodesale(_new_nodesale: address)`
**Purpose**: Updates nodesale address (Paloma-only).

**Access Control**: Paloma bridge only

#### `set_paloma()`
**Purpose**: Sets Paloma identifier (compass-only).

**Access Control**: Compass contract only

#### `create_bot(_user_id: uint256)`
**Purpose**: Creates a new FiatBot instance for a user (Paloma-only).

**Parameters**:
- `_user_id`: Unique user identifier

**Access Control**: Paloma bridge only

**Security Checks**:
- Ensures bot doesn't already exist
- Validates user_id is positive

**State Changes**:
- Deploys new FiatBot contract
- Records bot address
- Emits `BotCreated` event

#### `pay_for_token(_user_id: uint256, _token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32)`
**Purpose**: Processes token payment through user's bot (Paloma-only).

**Parameters**: Same as PalomaNodeSale.pay_for_token

**Access Control**: Paloma bridge only

**Security Checks**:
- Validates user_id and bot existence

**State Changes**:
- Calls bot's pay_for_token function

#### `activate_wallet(_user_id: uint256, _paloma: bytes32, _purchased_in_v1: bool)`
**Purpose**: Activates wallet through user's bot (Paloma-only).

**Parameters**: Same as PalomaNodeSale.activate_wallet

**Access Control**: Paloma bridge only

#### `refund(_user_id: uint256, _recipient: address, _token: address, _amount: uint256)`
**Purpose**: Processes refund through user's bot (Paloma-only).

**Parameters**:
- `_user_id`: User identifier
- `_recipient`: Refund recipient
- `_token`: Token to refund (zero for ETH)
- `_amount`: Refund amount

**Access Control**: Paloma bridge only

### FiatBot Contract Functions

#### Constructor (`__init__`)
**Purpose**: Records factory address as immutable.

#### `pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32)`
**Purpose**: Proxy function for token payments (factory-only).

**Access Control**: Factory only

**State Changes**:
- Approves tokens for nodesale contract
- Calls nodesale.pay_for_token
- Emits `PurchasedFiat` event

#### `activate_wallet(_paloma: bytes32, _purchased_in_v1: bool)`
**Purpose**: Proxy function for wallet activation (factory-only).

**Access Control**: Factory only

**State Changes**:
- Calls nodesale.activate_wallet
- Emits `ActivatedFiat` event

#### `refund(_recipient: address, _token: address, _amount: uint256)`
**Purpose**: Processes refunds (factory-only).

**Parameters**:
- `_recipient`: Refund recipient
- `_token`: Token to refund (zero for ETH)
- `_amount`: Refund amount

**Access Control**: Factory only

**State Changes**:
- Transfers tokens or ETH to recipient
- Emits `Refund` event

## Testing

### Prerequisites

1. Install Ape Framework:
```bash
pip install eth-ape
```

2. Install Vyper:
```bash
pip install vyper
```

3. Install test dependencies:
```bash
pip install pytest
```

### Running Tests

1. **Run all tests**:
```bash
ape test
```

2. **Run specific test file**:
```bash
ape test tests/test_nodeLicense5.py
```

3. **Run with verbose output**:
```bash
ape test -v
```

4. **Run with coverage**:
```bash
ape test --coverage
```

5. **Run specific test function**:
```bash
ape test tests/test_nodeLicense5.py::test_paloma_node_sale
```

### Test Structure

The test suite includes:

- **Contract deployment tests**: Verify correct initialization
- **Access control tests**: Ensure only authorized users can call functions
- **Functionality tests**: Test core business logic
- **Edge case tests**: Test boundary conditions and error cases
- **Integration tests**: Test interactions between contracts

### Example Test Execution

```bash
# Run the main test suite
ape test tests/test_nodeLicense5.py -v

# Expected output includes:
# - Contract deployment verification
# - Wallet activation tests
# - Promo code creation and usage
# - Payment processing tests
# - Access control validation
# - Error handling verification
```

### Test Configuration

The project uses Ape Framework with the following configuration:

- **Network**: Arbitrum mainnet fork for testing
- **Provider**: Foundry for local development
- **Gas**: Auto-estimation with 1.2x multiplier
- **Vyper Version**: 0.4.0
- **EVM Version**: Cancun

### Manual Testing

For manual testing and deployment:

1. **Deploy to testnet**:
```bash
ape run scripts/deploy.py --network arbitrum:testnet
```

2. **Deploy to mainnet**:
```bash
ape run scripts/deploy.py --network arbitrum:mainnet
```

3. **Deploy blueprint**:
```bash
ape run scripts/deploy_blueprint.py
```

4. **Deploy factory**:
```bash
ape run scripts/deploy_factory.py
```

## Security Considerations

### Access Control
- Admin functions are protected by `_admin_check()`
- Paloma functions are protected by `_paloma_check()`
- Factory functions are protected by `_factory_check()`

### Reentrancy Protection
- Critical functions use `@nonreentrant` decorator
- State changes occur before external calls

### Input Validation
- All addresses are validated for non-zero values
- Percentages are bounded to prevent excessive fees
- Timestamps are validated for logical consistency

### Fee Management
- Processing fees are fixed amounts
- Slippage fees are percentage-based with caps
- Referral rewards are percentage-based with validation

### Cross-Chain Security
- Paloma bridge authentication for cross-chain operations
- Nonce-based replay protection
- Compass contract validation

## Deployment

The system supports deployment across multiple networks:

- **Arbitrum**: Main deployment network
- **Ethereum**: Secondary deployment
- **BSC**: Binance Smart Chain deployment
- **Polygon**: Polygon network deployment
- **Base**: Coinbase L2 deployment
- **Optimism**: Optimism L2 deployment

Each network has specific addresses for:
- Compass contracts
- Swap routers
- USDC tokens
- Fund receivers
- V1 contracts

## License

Apache 2.0 License
