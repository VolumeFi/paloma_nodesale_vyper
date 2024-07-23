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
    amountIn: uint256
    amountOutMinimum: uint256
    sqrtPriceLimitX96: uint160

struct ExactOutputSingleParams:
    tokenIn: address
    tokenOut: address
    fee: uint24
    recipient: address
    amountOut: uint256
    amountInMaximum: uint256
    sqrtPriceLimitX96: uint160

struct Tier:
    price: uint256
    quantity: uint256

struct PromoCode:
    recipient: address
    active: bool
    received_lifetime: uint256

event PromoCodeCreated:
    promo_code: String
    recipient: address

event PromoCodeRemoved:
    promo_code: String

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

REWARD_TOKEN: public(immutable(address))
SWAP_ROUTER_02: public(immutable(address))
WETH9: public(immutable(address))
MAX_MINTABLE_AMOUNT: constant(uint256) = 40

# Storage
token_owner: public(HashMap(uint256, address))
token_approvals: public(HashMap(uint256, address))
operator_approvals: public(HashMap(address, HashMap(address, bool)))
token_URIs: public(HashMap(uint256, String))
total_supply: public(uint256)
total_supply_all_chain: public(uint256)
paloma: public(bytes32)
compass: public(address)
paid_amount: public(HashMap(address, uint256))
funds_receiver: public(address)
referral_discount_percentage: public(uint256)
referral_reward_percentage: public(uint256)
token_ids: public(uint256)
max_supply: public(uint256)
promo_codes: HashMap[String, PromoCode]
mint_timestamps: HashMap[uint256, uint256]
referral_rewards: HashMap[address, uint256]
average_cost: HashMap[uint256, uint256]
whitelist_amounts: HashMap[address, uint256]

interface ISwapRouter02:
    def exactInputSingle(params: ExactInputSingleParams) -> uint256: view
    def exactOutputSingle(params: ExactOutputSingleParams) -> uint256: view
    def exactInputMultiStep(params: ExactInputParams) -> uint256: view
    def exactOutputMultiStep(params: ExactOutputParams) -> uint256: view

interface IWETH:
    def deposit(): payable

interface ERC20:
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

# Constructor
@external
@deploy
def __init__(_compass: address, _swap_router: address, _reward_token: address, _weth9: address):
    self.total_supply = 0
    self.compass = _compass
    REWARD_TOKEN = _reward_token
    SWAP_ROUTER_02 = _swap_router
    WETH9 = _weth9
    log UpdateCompass(empty(address), _compass)

@view
@external
def tokenURI(_token_id: uint256) -> String:
    return self.token_metadata[_token_id]

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
def create_promo_code(_promo_code: String, _recipient: address):
    self._paloma_check()

    assert _recipient != empty(address), "Recipient address cannot be zero"
    self.promo_codes[_promo_code] = PromoCode(_recipient, True, 0)
    log PromoCodeCreated(_promo_code, _recipient)
    
@external
def remove_promo_code(_promo_code: String):
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

    assert _new_referral_discount_percentage <= 99, "Referral discount percentage cannot be greater than 99"
    assert _new_referral_reward_percentage <= 99, "Referral reward percentage cannot be greater than 99"
    self.referral_discount_percentage = _new_referral_discount_percentage
    self.referral_reward_percentage = _new_referral_reward_percentage
    log ReferralRewardPercentagesChanged(
        _new_referral_discount_percentage,
        _new_referral_reward_percentage,
    )

@external
def claim_referral_reward():
    assert self.claimable, "Claiming of referral rewards is currently disabled"
    _reward: uint256 = self.referral_reward[msg.sender]
    assert reward > 0, "No referral reward to claim"
    self.referral_reward[msg.sender] = 0
    assert ERC20(REWARD_TOKEN).transfer(msg.sender, _reward, default_return_value=True), "Claim Failed"
    log RewardClaimed(msg.sender, _reward)

@external
def update_whitelist_amounts(_to_whitelist: address, _amount: uint256):
    self._paloma_check()
    self.whitelist_amounts[_to_whitelist] = _amount
    log WhitelistAmountUpdatedByAdmin(_to_whitelist, _amount)

@external
@view
def get_promo_code(_promo_code: String) -> PromoCode:
    return self.promo_codes[_promo_code]

# Minting
@internal
def _mint(_to: address, _token_id: uint256):
    assert _token_id not in self.token_owner, "Token already exists"
    self.token_owner[_token_id] = _to
    self.total_supply += 1
    log Transfer(empty(address), _to, _token_id)

@external
def mint(_to: address, _amount: uint256, _promo_code_id: String, _average_cost: uint256):
    self._paloma_check()
    _promo_code: PromoCode = self.promo_codes[_promo_code_id]
    _token_id: uint256 = self._token_id
    assert _amount > 0, "Amount must be greater than 0"
    assert _promo_code.recipient != _to, "Referral address cannot be the senders address"
    assert (_promo_code.recipient != empty(address) and _promo_code.active) or _promo_code.recipient == empty(address), "Invalid or inactive promo code"

    for i: uint256 in range(MAX_MINTABLE_AMOUNT):
        if i >= _amount:
            break
        _token_id += 1
        self._mint(_to, _token_id)
        self.mint_timestamps[_token_id] = block.timestamp
        self.average_cost[_token_id] = _average_cost
        log NFTMinted(_to, _token_id, _average_cost)

    _referral_reward: uint256 = 0
    _final_price: uint256 = _amount * _average_cost
    if _promo_code.recipient != empty(address):
        _referral_reward = _final_price * self.referral_reward_percentage / 100
        self.referral_rewards[_promo_code.recipient] += _referral_reward
        self.promo_codes[_promo_code_id].received_lifetime += _referral_reward
        log ReferralReward(_to, _promo_code.recipient, _referral_reward)

@external
def refund(_to: address, _amount: uint256):
    self._paloma_check()
    assert _amount > 0, "Amount must be greater than 0"
    assert ERC20(REWARD_TOKEN).transfer(_to, _amount, default_return_value=True), "refund Failed"
    self.paid_amount[_to] = self.paid_amount[_to] - _amount
    log RefundOccurred(_to, _amount)

@external
def pay_for_token(_token_in: address, _amount_in: uint256):
    ERC20(_token_in).approve(SWAP_ROUTER_02, _amount_in)

    _params: ExactOutputSingleParams = ExactOutputSingleParams(
        tokenIn = _token_in,
        tokenOut = REWARD_TOKEN,
        fee = 3000,
        recipient = _sender,
        deadline = block.timestamp,
        amountOut = 50*10**6,
        amountInMaximum = _amount_in,
        sqrtPriceLimitX96 = 0
    )

    assert ISwapRouter02(SWAP_ROUTER_02).exactOutputSingle(_params), "swap Failed"

    self.paid_amount[msg.sender] = self.paid_amount[msg.sender] + _amount_out

@payable
@external
def pay_for_eth():
    # Wrap ETH to WETH9
    IWETH(WETH9).deposit(value=msg.value)

    # Approve WETH9 for the swap router
    ERC20(WETH9).approve(SWAP_ROUTER_02, msg.value)

    # Create the exact input single params
    _params: ExactInputSingleParams = ExactInputSingleParams(
        tokenIn = WETH9,
        tokenOut = REWARD_TOKEN,
        fee = 3000,
        recipient = msg.sender,
        amountIn = msg.value,
        amountOutMinimum = 50 * 10**6,  # 50 USDC # need to change
        sqrtPriceLimitX96 = 0
    )

    # Execute the swap
    assert ISwapRouter02(SWAP_ROUTER_02).exactInputSingle(_params), "swap ETH Failed"

    self.paid_amount[msg.sender] = self.paid_amount[msg.sender] + _amount_out

@external
def withdraw_funds(_amount: uint256):
    self._fund_receiver_check()
    _funds_receiver: address = self.funds_receiver
    assert ERC20(REWARD_TOKEN).transfer(_funds_receiver, _amount, default_return_value=True), "fund withdraw Failed"

    log FundsWithdrawn(msg.sender, _amount)

# ERC721 Interface
@view
@external
def balanceOf(_owner: address) -> uint256:
    _balance: uint256 = 0
    _token_owner: address = self.token_owner
    for _token_id in _token_owner:
        if _token_owner[_token_id] == _owner:
            _balance += 1
    return _balance

@view
@external
def ownerOf(_token_id: uint256) -> address:
    return self.token_owner[_token_id]

@external
@payable
def safeTransferFrom(_from: address, _to: address, _token_id: uint256, _data: Bytes[1024]=b""):
    self.transferFrom(_from, _to, _token_id)

@external
@payable
def transferFrom(_from: address, _to: address, _token_id: uint256):
    raise "transfer isnt available"

@external
@payable
def approve(_to: address, _token_id: uint256):
    assert self.token_owner[_token_id] != empty(address), "Token does not exist"
    self.token_approvals[_token_id] = _to
    log Approval(self.token_owner[_token_id], _to, _token_id)

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
