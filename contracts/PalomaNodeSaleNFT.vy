#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Paloma Node Sale NFT ERC721 Contract
@license    Apache 2.0
@author     Volume.finance
"""

# Events
event Transfer: 
    _from: indexed(address)
    _to: indexed(address)
    _token_id: indexed(uint256)

event Approval: 
    _owner: indexed(address)
    _approved: indexed(address)
    _token_id: indexed(uint256)

event ApprovalForAll: 
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool

event SetPaloma:
    paloma: bytes32

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateAdmin:
    old_admin: address
    new_admin: address

struct ExactInputSingleParams:
    tokenIn: address
    tokenOut: address
    fee: uint24
    recipient: address
    amountIn: uint256
    amountOutMinimum: uint256
    sqrtPriceLimitX96: uint160

struct PromoCode:
    recipient: address
    active: bool

struct Tier:
    price: uint256
    quantity: uint256

event PromoCodeCreated:
    promo_code: bytes32
    recipient: address

event PromoCodeRemoved:
    promo_code: bytes32

event RewardClaimed:
    claimer: indexed(address)
    amount: uint256

event ReferralRewardPercentagesChanged:
    referral_discount_percentage: uint256
    referral_reward_percentage: uint256

event StartEndTimestampChanged:
    new_start_timestamp: uint256
    new_end_timestamp: uint256

event RefundRequested:
    refundee: indexed(address)
    amount: uint256

event RefundOccurred:
    refundee: indexed(address)
    amount: uint256

event ReferralReward:
    referral_address: indexed(address)
    amount: uint256

event FundsWithdrawn:
    admin: indexed(address)
    amount: uint256

event FundsReceiverChanged:
    admin: indexed(address)
    new_funds_receiver: address

event FeeReceiverChanged:
    admin: indexed(address)
    new_fee_receiver: address

event WhitelistAmountUpdatedByAdmin:
    redeemer: indexed(address)
    new_amount: uint256

event WhitelistAmountRedeemed:
    redeemer: indexed(address)
    new_amount: uint256

event NFTMinted:
    buyer: address
    token_id: uint256
    average_cost: uint256
    paloma: bytes32

event NodeSold:
    buyer: address
    paloma: bytes32
    node_count: uint256
    grain_amount: uint256 

event Purchased:
    buyer: indexed(address)
    token_in: address
    usd_amount: uint256
    node_count: uint256
    average_cost: uint256
    promo_code: bytes32
    paloma: bytes32

event PricingTierSetOrAdded:
    index: uint256
    price: uint256
    quantity: uint256

REWARD_TOKEN: public(immutable(address))
SWAP_ROUTER_02: public(immutable(address))
WETH9: public(immutable(address))
MAX_MINTABLE_AMOUNT: constant(uint256) = 1000
MAX_PRICING_TIERS_LEN: constant(uint256) = 40
GRAINS_PER_NODE: constant(uint256) = 50000

# Storage
ownerOf: public(HashMap[uint256, address])
balanceOf: public(HashMap[address, uint256])
getApproved: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
total_supply: public(uint256)
max_supply: public(uint256)
paloma: public(bytes32)
compass: public(address)
admin: public(address)
paid_amount: public(HashMap[address, uint256])
funds_receiver: public(address)
referral_discount_percentage: public(uint256)
referral_reward_percentage: public(uint256)
pricing_tiers: public(HashMap[uint256, Tier])
pricing_tiers_len: public(uint256)
promo_codes: public(HashMap[bytes32, PromoCode])
mint_timestamps: public(HashMap[uint256, uint256])
average_cost: public(HashMap[uint256, uint256])
referral_rewards: public(HashMap[address, uint256])
referral_rewards_sum: public(uint256)
whitelist_amounts: public(HashMap[address, uint256])
withdrawable_funds: public(uint256)
start_timestamp: public(uint256)
end_timestamp: public(uint256)
processing_fee: public(uint256)
fee_receiver: public(address)

interface ISwapRouter02:
    def exactInputSingle(params: ExactInputSingleParams) -> uint256: payable
    def WETH9() -> address: view

interface IWETH:
    def deposit(): payable

interface ERC20:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_owner: address) -> uint256: view

# Constructor
@deploy
def __init__(_compass: address, _swap_router: address, _reward_token: address, _admin: address, _fund_receiver: address, _fee_receiver: address, _start_timestamp: uint256, _end_timestamp: uint256):
    self.compass = _compass
    self.admin = _admin
    self.funds_receiver = _fund_receiver
    self.fee_receiver = _fee_receiver
    self.start_timestamp = _start_timestamp
    self.end_timestamp = _end_timestamp
    REWARD_TOKEN = _reward_token
    SWAP_ROUTER_02 = _swap_router
    WETH9 = staticcall ISwapRouter02(_swap_router).WETH9()
    log UpdateCompass(empty(address), _compass)
    log UpdateAdmin(empty(address), _admin)
    log FundsReceiverChanged(empty(address), _fund_receiver)
    log FeeReceiverChanged(empty(address), _fee_receiver)
    log StartEndTimestampChanged(_start_timestamp, _end_timestamp)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@internal
def _fund_receiver_check():
    assert msg.sender == self.funds_receiver, "Not fund receiver"

@internal
def _fee_receiver_check():
    assert msg.sender == self.fee_receiver, "Not fee receiver"

@internal
def _admin_check():
    assert msg.sender == self.admin, "Not admin"

@external
def update_compass(_new_compass: address):
    self._paloma_check()
    self.compass = _new_compass
    log UpdateCompass(msg.sender, _new_compass)

@external
def update_admin(_new_admin: address):
    self._admin_check()
    self.admin = _new_admin
    log UpdateAdmin(msg.sender, _new_admin)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def create_promo_code(_promo_code: bytes32, _recipient: address):
    self._admin_check()

    assert _recipient != empty(address), "Recipient cannot be zero"
    self.promo_codes[_promo_code] = PromoCode(recipient=_recipient, active=True)
    log PromoCodeCreated(_promo_code, _recipient)
    
@external
def remove_promo_code(_promo_code: bytes32):
    self._admin_check()

    assert self.promo_codes[_promo_code].recipient != empty(address), "Promo code does not exist"
    self.promo_codes[_promo_code].active = False  # 'active' is set to False
    log PromoCodeRemoved(_promo_code)

@external
def set_funds_receiver(_new_funds_receiver: address):
    self._fund_receiver_check()

    assert _new_funds_receiver != empty(address), "FundsReceiver cannot be zero"
    self.funds_receiver = _new_funds_receiver
    log FundsReceiverChanged(msg.sender, _new_funds_receiver)

@external
def set_fee_receiver(_new_fee_receiver: address):
    self._fee_receiver_check()

    assert _new_fee_receiver != empty(address), "FeeReceiver cannot be zero"
    self.fee_receiver = _new_fee_receiver
    log FeeReceiverChanged(msg.sender, _new_fee_receiver)

@external
def set_referral_percentages(
    _new_referral_discount_percentage: uint256,
    _new_referral_reward_percentage: uint256,
):
    self._admin_check()

    assert _new_referral_discount_percentage <= 9900, "Discount p exceed"
    assert _new_referral_reward_percentage <= 9900, "Reward p exceed"
    self.referral_discount_percentage = _new_referral_discount_percentage
    self.referral_reward_percentage = _new_referral_reward_percentage
    log ReferralRewardPercentagesChanged(
        _new_referral_discount_percentage,
        _new_referral_reward_percentage,
    )

@external
def set_start_end_timestamp(
    _new_start_timestamp: uint256,
    _new_end_timestamp: uint256,
):
    self._admin_check()
    assert _new_start_timestamp > 0, "Invalid start date"
    assert _new_end_timestamp > 0, "Invalid end date"
    self.start_timestamp = _new_start_timestamp
    self.end_timestamp = _new_end_timestamp
    log StartEndTimestampChanged(_new_start_timestamp, _new_end_timestamp)

@external
def set_or_add_pricing_tier(
    _index: uint256,
    _price: uint256,
    _quantity: uint256,
):
    self._admin_check()

    _max_supply: uint256 = self.max_supply
    _pricing_tiers_len: uint256 = self.pricing_tiers_len
    if _index < _pricing_tiers_len:
        _max_supply = unsafe_sub(_max_supply, self.pricing_tiers[_index].quantity)
        self.pricing_tiers[_index] = Tier(price=_price, quantity=_quantity)
    elif _index == _pricing_tiers_len:
        self.pricing_tiers_len = unsafe_add(_pricing_tiers_len, 1)
        self.pricing_tiers[_index] = Tier(price=_price, quantity=_quantity)
    self.max_supply = unsafe_add(_max_supply, _quantity)
    log PricingTierSetOrAdded(_index, _price, _quantity)

@external
def claim_referral_reward():
    _rewards: uint256 = self.referral_rewards[msg.sender]
    _rewards_sum: uint256 = self.referral_rewards_sum
    assert _rewards > 0, "No reward to claim"
    self.referral_rewards[msg.sender] = 0
    self.referral_rewards_sum = unsafe_sub(_rewards_sum, _rewards)
    assert extcall ERC20(REWARD_TOKEN).transfer(msg.sender, _rewards, default_return_value=True), "Claim Failed"
    log RewardClaimed(msg.sender, _rewards)

@external
def update_whitelist_amounts(_to_whitelist: address, _amount: uint256):
    self._admin_check()
    self.whitelist_amounts[_to_whitelist] = _amount
    log WhitelistAmountUpdatedByAdmin(_to_whitelist, _amount)

@internal
@view
def _price(_amount: uint256, _promo_code: bytes32) -> uint256:
    _total_supply: uint256 = self.total_supply
    _total_cost: uint256 = 0
    _remaining: uint256 = _amount
    _tier_sum: uint256 = 0
    _len_price_tiers: uint256 = self.pricing_tiers_len
    for i: uint256 in range(MAX_PRICING_TIERS_LEN):
        if i >= _len_price_tiers:
            break
        _pricing_tier: Tier = self.pricing_tiers[i]
        _tier_sum = unsafe_add(_tier_sum, _pricing_tier.quantity)
        _available_in_this_tier: uint256 = 0
        if _tier_sum > _total_supply:
            _available_in_this_tier = unsafe_sub(_tier_sum, _total_supply)
        else:
            _available_in_this_tier = 0

        if _remaining <= _available_in_this_tier:
            _total_cost = unsafe_add(_total_cost, unsafe_mul(_remaining, _pricing_tier.price))
            _remaining = 0
            break
        else:
            _total_cost = unsafe_add(_total_cost, unsafe_mul(_available_in_this_tier, _pricing_tier.price))
            _remaining = unsafe_sub(_remaining, _available_in_this_tier)
            _total_supply = unsafe_add(_total_supply, _available_in_this_tier)
    
    assert _remaining == 0, "Not enough licenses"

    if (self.promo_codes[_promo_code].active):
        _total_cost = unsafe_div(unsafe_mul(_total_cost, unsafe_sub(10000, self.referral_discount_percentage)), 10000)

    return _total_cost

@external
@view
def price(_amount: uint256, _promo_code: bytes32) -> uint256:
    assert _amount > 0, "Amount cant be zero"

    _total_cost: uint256 = self._price(_amount, _promo_code)

    return _total_cost

# Minting
@internal
def _mint(_to: address, _token_id: uint256):
    assert self.ownerOf[_token_id] == empty(address), "Token already exists"
    self.ownerOf[_token_id] = _to
    self.balanceOf[_to] = unsafe_add(self.balanceOf[_to], 1)
    self.total_supply = unsafe_add(self.total_supply, 1)
    log Transfer(empty(address), _to, _token_id)

@external
def mint(_to: address, _amount: uint256, _promo_code: bytes32, _paloma: bytes32, _paid_amount: uint256):
    self._paloma_check()

    _promo_codes: PromoCode = self.promo_codes[_promo_code]
    _token_id: uint256 = self.total_supply
    if _token_id + _amount > self.max_supply:
        log RefundRequested(_to, _paid_amount)
        return
    if _amount <= 0:
        log RefundRequested(_to, _paid_amount)
        return
    if _to == empty(address):
        log RefundRequested(_to, _paid_amount)
        return
    if _promo_codes.recipient == _to:
        log RefundRequested(_to, _paid_amount)
        return
    if _promo_codes.recipient == empty(address) and _promo_codes.active:
        log RefundRequested(_to, _paid_amount)
        return

    _final_cost: uint256 = self._price(_amount, _promo_code)
    if _final_cost != _paid_amount:
        log RefundRequested(_to, _paid_amount)
        return

    _average_cost: uint256 = unsafe_div(_final_cost, _amount)

    for i: uint256 in range(MAX_MINTABLE_AMOUNT):
        if i >= _amount:
            break
        _token_id = unsafe_add(_token_id, 1)
        self._mint(_to, _token_id)
        self.mint_timestamps[_token_id] = block.timestamp
        self.average_cost[_token_id] = _average_cost
        log NFTMinted(_to, _token_id, _average_cost, _paloma)

    _grain_amount: uint256 = unsafe_mul(_amount, GRAINS_PER_NODE)
    log NodeSold(_to, _paloma, _amount, _grain_amount)

@external
def redeem_from_whitelist(_to: address, _paloma: bytes32):
    self._paloma_check()
    _whitelist_amounts: uint256 = self.whitelist_amounts[_to]
    assert _whitelist_amounts > 0, "Invalid whitelist amount"
    
    _token_id: uint256 = self.total_supply
    _to_mint: uint256 = _whitelist_amounts
    if _to_mint > MAX_MINTABLE_AMOUNT:
        _to_mint = MAX_MINTABLE_AMOUNT

    assert _token_id + _to_mint <= self.max_supply, "Exceeds max supply"

    for i: uint256 in range(MAX_MINTABLE_AMOUNT):
        if i >= _to_mint:
            break
        _token_id = unsafe_add(_token_id, 1)
        self._mint(_to, _token_id)
        self.mint_timestamps[_token_id] = block.timestamp
        log NFTMinted(_to, _token_id, 0, _paloma)
    
    _grain_amount: uint256 = unsafe_mul(_to_mint, GRAINS_PER_NODE)
    log NodeSold(_to, _paloma, _to_mint, _grain_amount)

    _new_amount: uint256 = unsafe_sub(_whitelist_amounts, _to_mint)
    self.whitelist_amounts[_to] = _new_amount
    log WhitelistAmountRedeemed(_to, _new_amount)

@external
def add_referral_reward(_recipient: address, _final_cost: uint256):
    self._paloma_check()
    _referral_reward: uint256 = 0

    if _recipient != empty(address):
        _referral_reward = unsafe_div(unsafe_mul(_final_cost, self.referral_reward_percentage), 10000)
        self.referral_rewards[_recipient] = self.referral_rewards[_recipient] + _referral_reward
        self.referral_rewards_sum = self.referral_rewards_sum + _referral_reward
    
    self.withdrawable_funds = self.withdrawable_funds + _final_cost - _referral_reward
    log ReferralReward(_recipient, _referral_reward)

@external
def refund(_to: address, _amount: uint256):
    self._paloma_check()
    assert _amount > 0, "Amount cant be zero"
    _paid_amount: uint256 = self.paid_amount[_to]
    assert _paid_amount >= _amount, "No balance to refund"
    assert extcall ERC20(REWARD_TOKEN).transfer(_to, _amount, default_return_value=True), "Refund failed"
    self.paid_amount[_to] = unsafe_sub(_paid_amount, _amount)
    log RefundOccurred(_to, _amount)

@external
def pay_for_token(_token_in: address, _amount_in: uint256, _node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _fee: uint24, _paloma: bytes32):
    assert block.timestamp >= self.start_timestamp
    assert block.timestamp < self.end_timestamp
    assert extcall ERC20(_token_in).approve(SWAP_ROUTER_02, _amount_in, default_return_value=True), "Approve failed"
    assert _node_count > 0, "Invalid node count"
    assert _total_cost > 0, "Invalid total cost"

    _processing_fee: uint256 = self.processing_fee
    _average_cost: uint256 = unsafe_div(_total_cost, _node_count)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = _token_in,
        tokenOut = REWARD_TOKEN,
        fee = _fee,
        recipient = self,
        amountIn = _amount_in,
        amountOutMinimum = unsafe_add(_total_cost, _processing_fee),
        sqrtPriceLimitX96 = 0
    )

    _swapped_amount: uint256 = extcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params)
    _paid_amount_without_fee: uint256 = unsafe_sub(_swapped_amount, _processing_fee)
    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _paid_amount_without_fee)
    log Purchased(msg.sender, _token_in, _paid_amount_without_fee, _node_count, _average_cost, _promo_code, _paloma)

    _fee_receiver: address = self.fee_receiver
    assert extcall ERC20(REWARD_TOKEN).transfer(_fee_receiver, _processing_fee, default_return_value=True), "Processing Fee Failed"

@payable
@external
def pay_for_eth(_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _fee: uint24, _paloma: bytes32):
    assert block.timestamp >= self.start_timestamp
    assert block.timestamp < self.end_timestamp
    assert _node_count > 0, "Invalid node count"
    assert _total_cost > 0, "Invalid total cost"
    
    _processing_fee: uint256 = self.processing_fee
    _average_cost: uint256 = unsafe_div(_total_cost, _node_count)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = WETH9,
        tokenOut = REWARD_TOKEN,
        fee = _fee,
        recipient = self,
        amountIn = msg.value,
        amountOutMinimum = unsafe_add(_total_cost, _processing_fee),
        sqrtPriceLimitX96 = 0
    )

    # Execute the swap
    _swapped_amount: uint256 = extcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params, value=msg.value)
    _paid_amount_without_fee: uint256 = unsafe_sub(_swapped_amount, _processing_fee)
    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _paid_amount_without_fee)
    log Purchased(msg.sender, empty(address), _paid_amount_without_fee, _node_count, _average_cost, _promo_code, _paloma)

    _fee_receiver: address = self.fee_receiver
    assert extcall ERC20(REWARD_TOKEN).transfer(_fee_receiver, _processing_fee, default_return_value=True), "Processing Fee Failed"

@external
def withdraw_funds():
    self._fund_receiver_check()
    _funds_receiver: address = self.funds_receiver
    _withdrawable_funds: uint256 = self.withdrawable_funds
    assert _withdrawable_funds > 0, "Not enough balance"
    assert extcall ERC20(REWARD_TOKEN).transfer(_funds_receiver, _withdrawable_funds, default_return_value=True), "Fund withdraw Failed"
    self.withdrawable_funds = 0
    log FundsWithdrawn(msg.sender, _withdrawable_funds)

@external
@payable
def safeTransferFrom(_from: address, _to: address, _token_id: uint256, _data: Bytes[1024]=b""):
    self._transferFrom(_from, _to, _token_id)

@internal
def _transferFrom(_from: address, _to: address, _token_id: uint256):
    raise "transfer isnt available"

@external
@payable
def transferFrom(_from: address, _to: address, _token_id: uint256):
    raise "transfer isnt available"

@external
@payable
def approve(_to: address, _token_id: uint256):
    assert self.ownerOf[_token_id] != empty(address), "Token does not exist"
    self.getApproved[_token_id] = _to
    log Approval(self.ownerOf[_token_id], _to, _token_id)

@external
def setApprovalForAll(_operator: address, _approved: bool):
    self.isApprovedForAll[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

@external
@payable
def __default__():
    pass
