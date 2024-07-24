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

struct ExactInputSingleParams:
    tokenIn: address
    tokenOut: address
    fee: uint24
    recipient: address
    deadline: uint256
    amountIn: uint256
    amountOutMinimum: uint256
    sqrtPriceLimitX96: uint160

struct ExactOutputSingleParams:
    tokenIn: address
    tokenOut: address
    fee: uint24
    recipient: address
    deadline: uint256
    amountOut: uint256
    amountInMaximum: uint256
    sqrtPriceLimitX96: uint160

struct PromoCode:
    recipient: address
    active: bool
    received_lifetime: uint256

event RewardClaimed:
    claimer: address
    amount: uint256

event ReferralRewardPercentagesChanged:
    referral_discount_percentage: uint256
    referral_reward_percentage: uint256

event RefundOccurred:
    refundee: address
    amount: uint256

event FundsWithdrawn:
    admin: address
    amount: uint256

event FundsReceiverChanged:
    admin: address
    new_funds_receiver: address

event ClaimableChanged:
    admin: address
    new_claimable_state: bool

event Purchased:
    buyer: address
    token_in: address
    usd_amount: uint256
    node_count: uint256
    average_cost: uint256
    promo_code: String[10]
    paloma: bytes32

REWARD_TOKEN: public(immutable(address))
SWAP_ROUTER_02: public(immutable(address))
WETH9: public(immutable(address))
MAX_MINTABLE_AMOUNT: constant(uint256) = 40

# Storage
ownerOf: public(HashMap[uint256, address])
balanceOf: public(HashMap[address, uint256])
token_approvals: public(HashMap[uint256, address])
operator_approvals: public(HashMap[address, HashMap[address, bool]])
total_supply: public(uint256)
paloma: public(bytes32)
compass: public(address)
paid_amount: public(HashMap[address, uint256])
funds_receiver: public(address)
referral_discount_percentage: public(uint256)
referral_reward_percentage: public(uint256)
claimable: public(bool)
mint_timestamps: HashMap[uint256, uint256]
referral_rewards: HashMap[address, uint256]

interface ISwapRouter02:
    def exactInputSingle(params: ExactInputSingleParams) -> uint256: view
    def exactOutputSingle(params: ExactOutputSingleParams) -> uint256: view

interface IWETH:
    def deposit(): payable

interface ERC20:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

# Constructor
@deploy
def __init__(_compass: address, _swap_router: address, _reward_token: address, _weth9: address):
    self.total_supply = 0
    self.compass = _compass
    REWARD_TOKEN = _reward_token
    SWAP_ROUTER_02 = _swap_router
    WETH9 = _weth9
    log UpdateCompass(empty(address), _compass)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@internal
def _fund_receiver_check():
    assert msg.sender == self.funds_receiver, "Not fund receiver"

@external
def update_compass(_new_compass: address):
    self._paloma_check()
    self.compass = _new_compass
    log UpdateCompass(msg.sender, _new_compass)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def set_claimable(_new_claimable: bool):
    self._paloma_check()

    self.claimable = _new_claimable
    log ClaimableChanged(msg.sender, _new_claimable)

@external
def set_funds_receiver(_new_funds_receiver: address):
    self._fund_receiver_check()

    assert _new_funds_receiver != empty(address), "New fundsReceiver cannot be the zero address"
    self.funds_receiver = _new_funds_receiver
    log FundsReceiverChanged(msg.sender, _new_funds_receiver)

@external
def set_referral_percentages(
    _new_referral_discount_percentage: uint256,
    _new_referral_reward_percentage: uint256,
):
    self._paloma_check()

    assert _new_referral_discount_percentage <= 9900, "Referral discount percentage cannot be greater than 99"
    assert _new_referral_reward_percentage <= 9900, "Referral reward percentage cannot be greater than 99"
    self.referral_discount_percentage = _new_referral_discount_percentage
    self.referral_reward_percentage = _new_referral_reward_percentage
    log ReferralRewardPercentagesChanged(
        _new_referral_discount_percentage,
        _new_referral_reward_percentage,
    )

@external
def claim_referral_reward():
    assert self.claimable, "Claim is not available"
    _rewards: uint256 = self.referral_rewards[msg.sender]
    assert _rewards > 0, "No referral reward to claim"
    self.referral_rewards[msg.sender] = 0
    assert extcall ERC20(REWARD_TOKEN).transfer(msg.sender, _rewards, default_return_value=True), "Claim Failed"
    log RewardClaimed(msg.sender, _rewards)

@external
def refund(_to: address, _amount: uint256):
    self._paloma_check()
    assert _amount > 0, "Amount must be greater than 0"
    assert extcall ERC20(REWARD_TOKEN).transfer(_to, _amount, default_return_value=True), "refund Failed"
    self.paid_amount[_to] = unsafe_sub(self.paid_amount[_to], _amount)
    log RefundOccurred(_to, _amount)

@external
def pay_for_token(_token_in: address, _amount_in: uint256, _node_count: uint256, _average_cost: uint256, _promo_code_id: String[10], _paloma: bytes32):
    assert extcall ERC20(_token_in).approve(SWAP_ROUTER_02, _amount_in), "approve Failed"

    _usd_amount: uint256 = unsafe_mul(_node_count, _average_cost)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = _token_in,
        tokenOut = REWARD_TOKEN,
        fee = 3000,
        recipient = self,
        deadline = block.timestamp,
        amountIn = _amount_in,
        amountOutMinimum = _usd_amount,
        sqrtPriceLimitX96 = 0
    )

    _swapped_amount: uint256 = staticcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params)

    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _swapped_amount)
    log Purchased(msg.sender, _token_in, _usd_amount, _node_count, _average_cost, _promo_code_id, _paloma)

@payable
@external
def pay_for_eth(_node_count: uint256, _average_cost: uint256, _promo_code_id: String[10], _paloma: bytes32):
    # Approve WETH9 for the swap router
    assert extcall ERC20(WETH9).approve(SWAP_ROUTER_02, msg.value), "appprove Failed"
    # Wrap ETH to WETH9
    extcall IWETH(WETH9).deposit(value=msg.value)

    _usd_amount: uint256 = unsafe_mul(_node_count, _average_cost)
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = WETH9,
        tokenOut = REWARD_TOKEN,
        fee = 3000,
        recipient = self,
        deadline = block.timestamp,
        amountIn = msg.value,
        amountOutMinimum = _usd_amount,
        sqrtPriceLimitX96 = 0
    )

    # Execute the swap
    _swapped_amount: uint256 = staticcall ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params)

    self.paid_amount[msg.sender] = unsafe_add(self.paid_amount[msg.sender], _swapped_amount)
    log Purchased(msg.sender, empty(address), _usd_amount, _node_count, _average_cost, _promo_code_id, _paloma)

@external
def withdraw_funds(_amount: uint256):
    self._fund_receiver_check()
    _funds_receiver: address = self.funds_receiver
    assert extcall ERC20(REWARD_TOKEN).transfer(_funds_receiver, _amount, default_return_value=True), "fund withdraw Failed"

    log FundsWithdrawn(msg.sender, _amount)

@external
@payable
def __default__():
    pass
