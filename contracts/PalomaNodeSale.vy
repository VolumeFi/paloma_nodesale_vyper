#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Paloma Node Sale Contract
@license    Apache 2.0
@author     Volume.finance
"""

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

event RewardClaimed:
    claimer: indexed(address)
    amount: uint256

event ReferralRewardPercentagesChanged:
    referral_discount_percentage: uint256
    referral_reward_percentage: uint256

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

event Purchased:
    buyer: indexed(address)
    token_in: address
    usd_amount: uint256
    node_count: uint256
    average_cost: uint256
    promo_code: bytes32
    paloma: bytes32

REWARD_TOKEN: public(immutable(address))
SWAP_ROUTER_02: public(immutable(address))
WETH9: public(immutable(address))

# Storage
paloma: public(bytes32)
compass: public(address)
admin: public(address)
paid_amount: public(HashMap[address, uint256])
funds_receiver: public(address)
referral_discount_percentage: public(uint256)
referral_reward_percentage: public(uint256)
referral_rewards: public(HashMap[address, uint256])
referral_rewards_sum: public(uint256)
withdrawable_funds: public(uint256)
start_timestamp: public(uint256)
end_timestamp: public(uint256)

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
def __init__(_compass: address, _swap_router: address, _reward_token: address, _admin: address, _fund_receiver: address, _start_timestamp: uint256, _end_timestamp: uint256):
    self.compass = _compass
    self.admin = _admin
    self.funds_receiver = _fund_receiver
    self.start_timestamp = _start_timestamp
    self.end_timestamp = _end_timestamp
    REWARD_TOKEN = _reward_token
    SWAP_ROUTER_02 = _swap_router
    WETH9 = staticcall ISwapRouter02(_swap_router).WETH9()
    log UpdateCompass(empty(address), _compass)
    log UpdateAdmin(empty(address), _admin)
    log FundsReceiverChanged(empty(address), _fund_receiver)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@internal
def _fund_receiver_check():
    assert msg.sender == self.funds_receiver, "Not fund receiver"

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
def set_funds_receiver(_new_funds_receiver: address):
    self._fund_receiver_check()

    assert _new_funds_receiver != empty(address), "FundsReceiver cannot be zero"
    self.funds_receiver = _new_funds_receiver
    log FundsReceiverChanged(msg.sender, _new_funds_receiver)

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
def claim_referral_reward():
    _rewards: uint256 = self.referral_rewards[msg.sender]
    _rewards_sum: uint256 = self.referral_rewards_sum
    assert _rewards > 0, "No reward to claim"
    self.referral_rewards[msg.sender] = 0
    self.referral_rewards_sum = unsafe_sub(_rewards_sum, _rewards)
    assert extcall ERC20(REWARD_TOKEN).transfer(msg.sender, _rewards, default_return_value=True), "Claim Failed"
    log RewardClaimed(msg.sender, _rewards)

@external
def add_referral_reward(_recipient: address, _final_cost: uint256):
    self._paloma_check()
    _referral_reward: uint256 = 0

    if _recipient != empty(address):
        _referral_reward = unsafe_div(unsafe_mul(_final_cost, self.referral_reward_percentage), 10000)
        self.referral_rewards[_recipient] = self.referral_rewards[_recipient] + _referral_reward
        self.referral_rewards_sum = self.referral_rewards_sum + _referral_reward
        log ReferralReward(_recipient, _referral_reward)

    self.withdrawable_funds = self.withdrawable_funds + _final_cost - _referral_reward

@external
def refund(_to: address, _amount: uint256):
    self._paloma_check()
    assert _amount > 0, "Amount cant be zero"
    _paid_amount: uint256 = self.paid_amount[_to]
    assert _paid_amount >= _amount, "No balance to refund"
    assert extcall ERC20(REWARD_TOKEN).transfer(_to, _amount, default_return_value=True), "refund Failed"
    self.paid_amount[_to] = unsafe_sub(_paid_amount, _amount)
    log RefundOccurred(_to, _amount)

@external
def pay_for_token(_token_in: address, _amount_in: uint256, _node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _fee: uint24, _paloma: bytes32):
    assert extcall ERC20(_token_in).approve(SWAP_ROUTER_02, _amount_in, default_return_value=True), "approve Failed"
    assert _node_count > 0, "Invalid node count"
    assert _total_cost > 0, "Invalid total cost"

    _average_cost: uint256 = unsafe_div(_total_cost, _node_count)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = _token_in,
        tokenOut = REWARD_TOKEN,
        fee = _fee,
        recipient = self,
        amountIn = _amount_in,
        amountOutMinimum = _total_cost,
        sqrtPriceLimitX96 = 0
    )

    _swapped_amount: uint256 = extcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params)

    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _swapped_amount)
    log Purchased(msg.sender, _token_in, _total_cost, _node_count, _average_cost, _promo_code, _paloma)

@payable
@external
def pay_for_eth(_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _fee: uint24, _paloma: bytes32):
    assert _node_count > 0, "Invalid node count"
    assert _total_cost > 0, "Invalid total cost"
    # # Approve WETH9 for the swap router
    # assert extcall ERC20(WETH9).approve(SWAP_ROUTER_02, msg.value), "appprove Failed"
    # # Wrap ETH to WETH9
    # extcall IWETH(WETH9).deposit(value=msg.value)

    _average_cost: uint256 = unsafe_div(_total_cost, _node_count)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = WETH9,
        tokenOut = REWARD_TOKEN,
        fee = _fee,
        recipient = self,
        amountIn = msg.value,
        amountOutMinimum = _average_cost,
        sqrtPriceLimitX96 = 0
    )

    # Execute the swap
    _swapped_amount: uint256 = extcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params, value=msg.value)

    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _swapped_amount)
    log Purchased(msg.sender, empty(address), _total_cost, _node_count, _average_cost, _promo_code, _paloma)

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
def __default__():
    pass
