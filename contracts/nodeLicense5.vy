#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title      Node License 5
@license    Apache 2.0
@author     Volume.finance
"""

funds_receiver: public(address)
max_supply: uint256
pricing_tiers: Tier[100]  # Assuming 100 tiers for now, adjust as needed
referral_discount_percentage: uint256
referral_reward_percentage: uint256
claimable: bool
mint_timestamps: uint256[uint256]  # Mapping from token ID to minting timestamp
promo_codes: PromoCode[string]  # Mapping from promo code to PromoCode struct
referral_rewards: uint256[address]  # Mapping from referral address to referral reward
average_cost: uint256[uint256]  # Mapping from token ID to average cost
whitelist_amounts: uint16[address]  # Mapping for whitelist to claim NFTs without a price

struct Tier:
    price: uint256
    quantity: uint256

struct PromoCode:
    recipient: address
    active: bool
    received_lifetime: uint256

event PromoCodeCreated:
    promo_code: string
    recipient: address

event PromoCodeRemoved:
    promo_code: string

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
    new_amount: uint16

event WhitelistAmountRedeemed:
    redeemer: address
    new_amount: uint16

@external
def create_promo_code(_promo_code: string, _recipient: address):
    assert _recipient!= ZERO_ADDRESS, "Recipient address cannot be zero"
    promo_codes[_promo_code] = PromoCode(_recipient, True, 0)
    log PromoCodeCreated(_promo_code, _recipient)

@external
def remove_promo_code(_promo_code: string):
    assert promo_codes[_promo_code].recipient!= ZERO_ADDRESS, "Promo code does not exist"
    promo_codes[_promo_code].active = False  # 'active' is set to False
    log PromoCodeRemoved(_promo_code)

@view
@external
def get_promo_code(_promo_code: string) -> PromoCode:
    return promo_codes[_promo_code]

@external
@payable
def __default__():
    pass
