#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Node License 5
@license    Apache 2.0
@author     Volume.finance
"""

name: public(String[32])
symbol: public(String[32])
token_name: public(String[32])
token_symbol: public(String[32])
owner_of: public(HashMap[uint256, address])
token_approvals: public(HashMap[uint256, address])
operator_approvals: public(HashMap[address, HashMap[address, bool]])
token_metadata: public(HashMap[uint256, String[32]])
owner_token_count: public(HashMap[address, uint256])
token_owner: public(HashMap[uint256, address])

funds_receiver: public(address)

max_supply: public(uint256)

pricing_tiers: Tier[40]

referral_discount_percentage: public(uint256)
referral_reward_percentage: public(uint256)

claimable: public(bool)

mint_timestamps: HashMap[uint256, uint256]
promo_codes: HashMap[String, PromoCode]
referral_rewards: HashMap[address, uint256]
average_cost: HashMap[uint256, uint256]
whitelist_amounts: HashMap[address, uint256]

paloma: public(bytes32)
compass: public(address)

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

event PricingTierSetOrAdded:
    index: uint256
    price: uint256
    quantity: uint256

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

event WhitelistAmountRedeemed:
    redeemer: address
    new_amount: uint256

@external
def __init__(_name: String[32], _symbol: String[32]):
    self.name = _name
    self.symbol = _symbol
    self.token_name = _name
    self.token_symbol = _symbol

@view
@external
def name() -> String[32]:
    return self.name

@view
@external
def symbol() -> String[32]:
    return self.symbol

@view
@external
def tokenURI(_tokenId: uint256) -> String[32]:
    return self.token_metadata[_tokenId]

@external
def balance_of(_owner: address) -> uint256:
    return self.owner_token_count[_owner]

@view
@external
def owner_of(_tokenId: uint256) -> address:
    return self.token_owner[_tokenId]

@external
def approve(_to: address, _tokenId: uint256):
    self.token_approvals[_tokenId] = _to

@external
def set_approval_for_all(_operator: address, _approved: bool):
    self.operator_approvals[msg.sender][_operator] = _approved

@view
@external
def get_approved(_tokenId: uint256) -> address:
    return self.token_approvals[_tokenId]

@view
@external
def is_approved_for_all(_owner: address, _operator: address) -> bool:
    return self.operator_approvals[_owner][_operator]

@internal
def _transfer(from: address, to: address, token_id: uint256):
    revert("NodeLicense: transfer is not allowed")

@external
def safe_transfer_from(_from: address, _to: address, _tokenId: uint256):
    self._transfer(_from, _to, _tokenId)

@external
def safe_transfer_from(_from: address, _to: address, _tokenId: uint256, _data: bytes[1024]):
    self._transfer(_from, _to, _tokenId)
    
@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

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

    assert _recipient != ZERO_ADDRESS, "Recipient address cannot be zero"
    self.promo_codes[_promo_code] = PromoCode(_recipient, True, 0)
    log PromoCodeCreated(_promo_code, _recipient)

@external
def remove_promo_code(_promo_code: String):
    self._paloma_check()

    assert self.promo_codes[_promo_code].recipient != ZERO_ADDRESS, "Promo code does not exist"
    self.promo_codes[_promo_code].active = False  # 'active' is set to False
    log PromoCodeRemoved(_promo_code)

@external
@view
def get_promo_code(_promo_code: String) -> PromoCode:
    return self.promo_codes[_promo_code]

@external
@view
def get_pricing_tiers_length() -> uint256:
    return len(self.pricing_tiers)

@external
@payable
def mint(_amount: uint256, _promo_code: String):
    pass
    
@external
def redeem_from_whitelist():
    pass

@external
@view
def price(_amount: uint256, _promo_code: String) -> uint256:
    total_supply: uint256 = self.total_supply()
    total_cost: uint256 = 0
    remaining: uint256 = _amount
    tier_sum: uint256 = 0

    for i: uint256 in range(len(self.pricing_tiers)):
        tier_sum += self.pricing_tiers[i].quantity
        available_in_this_tier: uint256 = tier_sum > total_supply ? tier_sum - total_supply : 0

        if remaining <= available_in_this_tier:
            total_cost += remaining * self.pricing_tiers[i].price
            remaining = 0
            break
        else:
            total_cost += available_in_this_tier * self.pricing_tiers[i].price
            remaining -= available_in_this_tier
            total_supply += available_in_this_tier

    assert remaining == 0, "Not enough licenses available for sale"

    # Apply discount if promo code is active
    if self.promo_codes[_promo_code].active:
        total_cost = total_cost * (100 - self.referral_discount_percentage) / 100

    return total_cost

@external
def claim_referral_reward():
    assert claimable, "Claiming of referral rewards is currently disabled"
    reward: uint256 = _referralRewards[msg.sender]
    require(reward > 0, "No referral reward to claim")
    _referralRewards[msg.sender] = 0
    (success: bool) = msg.sender.transfer(reward)
    require(success, "Transfer failed")
    log RewardClaimed(msg.sender, reward)

@external
def withdraw_funds():
    amount: uint256 = address(self).balance
    self.funds_receiver.transfer(amount)
    log FundsWithdrawn(msg.sender, amount)

@external
def set_claimable(new_claimable: bool):
    self.claimable = new_claimable
    log ClaimableChanged(msg.sender, new_claimable)

@external
def set_funds_receiver(new_funds_receiver: address):
    require(new_funds_receiver != address(0), "New fundsReceiver cannot be the zero address")
    self.funds_receiver = new_funds_receiver
    log FundsReceiverChanged(msg.sender, new_funds_receiver)

@external
def set_referral_percentages(
    new_referral_discount_percentage: uint256,
    new_referral_reward_percentage: uint256,
):
    require(new_referral_discount_percentage <= 99, "Referral discount percentage cannot be greater than 99")
    require(new_referral_reward_percentage <= 99, "Referral reward percentage cannot be greater than 99")
    self.referral_discount_percentage = new_referral_discount_percentage
    self.referral_reward_percentage = new_referral_reward_percentage
    log ReferralRewardPercentagesChanged(
        new_referral_discount_percentage,
        new_referral_reward_percentage,
    )

@external
def set_or_add_pricing_tier(index: uint256, price: uint256, quantity: uint256):
    if index < len(self.pricing_tiers):
        max_supply -= self.pricing_tiers[index].quantity
        self.pricing_tiers[index] = Tier(price, quantity)
    elif index == len(self.pricing_tiers):
        self.pricing_tiers.append(Tier(price, quantity))
    else:
        revert("Index out of bounds")

    max_supply += quantity
    log PricingTierSetOrAdded(index, price, quantity)

@external
@view
def get_pricing_tier(index: uint256) -> Tier:
    require(index < len(self.pricing_tiers), "Index out of bounds")
    return self.pricing_tiers[index]

@internal
def _update_whitelist_amounts(to_whitelist: address, amount: uint16):
    self.whitelist_amounts[to_whitelist] = amount
    log WhitelistAmountUpdatedByAdmin(to_whitelist, amount)

@external
def update_whitelist_amounts(to_whitelist: address[10], amounts: uint16[10]):
    require(len(to_whitelist) == len(amounts), "Invalid input")
    for i in range(len(to_whitelist)):
        self._update_whitelist_amounts(to_whitelist[i], amounts[i])

@external
@payable
def refund_node_license(_tokenId: uint256) -> None:
    assert _exists(_tokenId), "ERC721Metadata: Refund for nonexistent token"
    refund_amount: uint256 = self._average_cost[_tokenId]
    assert refund_amount > 0, "No funds to refund"
    self._average_cost[_tokenId] = 0
    raw_call(owner_of(_tokenId), value=refund_amount, gas=30000)
    log RefundOccurred(owner_of(_tokenId), refund_amount)
    self._burn(_tokenId)

@external
@view
def get_average_cost(_tokenId: uint256) -> uint256:
    assert _exists(_tokenId), "ERC721Metadata: Query for nonexistent token"
    return self._average_cost[_tokenId]

@external
@view
def get_mint_timestamp(_tokenId: uint256) -> uint256:
    assert _exists(_tokenId), "ERC721Metadata: Query for nonexistent token"
    return self._mint_timestamps[_tokenId]

@external
@payable
def __default__():
    pass
