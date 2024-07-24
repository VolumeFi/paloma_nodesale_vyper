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

event PromoCodeCreated:
    promo_code: String[10]
    recipient: address

event PromoCodeRemoved:
    promo_code: String[10]

event RewardClaimed:
    claimer: address
    amount: uint256

event ReferralRewardPercentagesChanged:
    referral_discount_percentage: uint256
    referral_reward_percentage: uint256

event RefundOccurred:
    refundee: address
    amount: uint256

event ReferralReward:
    buyer: address
    referral_address: address
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

event WhitelistAmountUpdatedByAdmin:
    redeemer: address
    new_amount: uint256

event NFTMinted:
    buyer: address
    token_id: uint256
    average_cost: uint256
    paloma: bytes32

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
promo_codes: HashMap[String[10], PromoCode]
mint_timestamps: HashMap[uint256, uint256]
referral_rewards: HashMap[address, uint256]
average_cost: HashMap[uint256, uint256]
whitelist_amounts: HashMap[address, uint256]

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
def create_promo_code(_promo_code: String[10], _recipient: address):
    self._paloma_check()

    assert _recipient != empty(address), "Recipient address cannot be zero"
    self.promo_codes[_promo_code] = PromoCode(recipient=_recipient, active=True, received_lifetime=0)
    log PromoCodeCreated(_promo_code, _recipient)
    
@external
def remove_promo_code(_promo_code: String[10]):
    self._paloma_check()

    assert self.promo_codes[_promo_code].recipient != empty(address), "Promo code does not exist"
    self.promo_codes[_promo_code].active = False  # 'active' is set to False
    log PromoCodeRemoved(_promo_code)

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
def update_whitelist_amounts(_to_whitelist: address, _amount: uint256):
    self._paloma_check()
    self.whitelist_amounts[_to_whitelist] = _amount
    log WhitelistAmountUpdatedByAdmin(_to_whitelist, _amount)

@external
@view
def get_promo_code(_promo_code: String[10]) -> PromoCode:
    return self.promo_codes[_promo_code]

# Minting
@internal
def _mint(_to: address, _token_id: uint256):
    assert self.ownerOf[_token_id] == empty(address), "Token already exists"
    self.ownerOf[_token_id] = _to
    self.balanceOf[_to] = unsafe_add(self.balanceOf[_to], 1)
    self.total_supply = unsafe_add(self.total_supply, 1)
    log Transfer(empty(address), _to, _token_id)

@external
def mint(_to: address, _amount: uint256, _promo_code_id: String[10], _average_cost: uint256, _paloma: bytes32):
    self._paloma_check()
    _promo_code: PromoCode = self.promo_codes[_promo_code_id]
    _token_id: uint256 = self.total_supply
    assert _amount > 0, "Amount must be greater than 0"
    assert _promo_code.recipient != _to, "Referral address cannot be the senders address"
    assert (_promo_code.recipient != empty(address) and _promo_code.active) or _promo_code.recipient == empty(address), "Invalid or inactive promo code"

    for i: uint256 in range(MAX_MINTABLE_AMOUNT):
        if i >= _amount:
            break
        _token_id = unsafe_add(_token_id, 1)
        self._mint(_to, _token_id)
        self.mint_timestamps[_token_id] = block.timestamp
        self.average_cost[_token_id] = _average_cost
        log NFTMinted(_to, _token_id, _average_cost, _paloma)

    _referral_reward: uint256 = 0
    _final_price: uint256 = unsafe_mul(_amount, _average_cost)
    if _promo_code.recipient != empty(address):
        _referral_reward = unsafe_div(unsafe_mul(_final_price, self.referral_reward_percentage), 10000)
        self.referral_rewards[_promo_code.recipient] = unsafe_add(self.referral_rewards[_promo_code.recipient], _referral_reward)
        self.promo_codes[_promo_code_id].received_lifetime = unsafe_add(_promo_code.received_lifetime, _referral_reward)
        log ReferralReward(_to, _promo_code.recipient, _referral_reward)

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
def safeTransferFrom(_from: address, _to: address, _token_id: uint256, _data: Bytes[1024]=b""):
    self._transferFrom(_from, _to, _token_id)

@internal
@payable
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
    self.token_approvals[_token_id] = _to
    log Approval(self.ownerOf[_token_id], _to, _token_id)

@external
def setApprovalForAll(_operator: address, _approved: bool):
    self.operator_approvals[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

@view
@external
def getApproved(_token_id: uint256) -> address:
    return self.token_approvals[_token_id]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return self.operator_approvals[_owner][_operator]

@external
@payable
def __default__():
    pass
