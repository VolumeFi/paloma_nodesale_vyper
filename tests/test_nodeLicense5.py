import pytest
from ape import project, accounts
from eth_abi import encode
from web3 import Web3

@pytest.fixture(scope="session")
def deployer():
    return accounts[0]

@pytest.fixture(scope="session")
def compass(accounts):
    return accounts[1]

def function_signature(str):
    return Web3.keccak(text=str)[:4]

@pytest.fixture(scope="session")
def contract(deployer, compass):
    contract = deployer.deploy(
        project.PalomaNodeSale,
        compass,  # compass
        "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",  # swap_router
        "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",  # reward_token
        deployer,
        "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294",  # fund_receiver
        "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74",  # fee_receiver
        1722988800,
        1726876800,
        5000000,
        50000000,
        500,
        1500
    )
    funcSig = function_signature("set_paloma()")
    addPayload = encode(["bytes32"], [b'123456'])
    payload = funcSig + addPayload
    contract(sender=compass, data=payload)

    return contract

def test_initialization(contract, deployer, compass):
    assert contract.admin() == deployer
    assert contract.compass() == compass
    assert contract.funds_receiver() == "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"
    assert contract.fee_receiver() == "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

def test_activate_wallet(contract, deployer):
    paloma = encode(["bytes32"], [b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xd4\x5d\x0b\xee\xea\xc4\xc2\xf2\x36\x22\x3a\x70\x27\x80\x76\x6e\xb2\x80\x03\x9c'])
    # paloma = b'\x00' * 32
    # print(contract)
    # print(paloma)
    contract.activate_wallet(paloma, sender=deployer)
    # assert contract.activate(deployer) == paloma

# def test_create_promo_code(contract, Deployer):
#     promo_code = b'\x01' * 32
#     recipient = accounts[5]
#     contract.create_promo_code(promo_code, recipient, sender=Deployer)
#     assert contract.promo_codes(promo_code).recipient == recipient

# def test_create_promo_code_non_admin(contract, deployer):
#     promo_code = b'\x01' * 32
#     recipient = accounts[5]
#     with pytest.raises(Exception):
#         contract.create_promo_code(promo_code, recipient, sender=deployer)

# def test_remove_promo_code(contract, admin):
#     promo_code = b'\x01' * 32
#     contract.remove_promo_code(promo_code, sender=admin)
#     assert not contract.promo_codes(promo_code).active

# def test_remove_promo_code_non_admin(contract, deployer):
#     promo_code = b'\x01' * 32
#     with pytest.raises(Exception):
#         contract.remove_promo_code(promo_code, sender=deployer)

# def test_update_whitelist_amounts(contract, admin):
#     to_whitelist = accounts[6]
#     amount = 1000
#     contract.update_whitelist_amounts(to_whitelist, amount, sender=admin)
#     assert contract.whitelist_amounts(to_whitelist) == amount

# def test_update_whitelist_amounts_non_admin(contract, deployer):
#     to_whitelist = accounts[6]
#     amount = 1000
#     with pytest.raises(Exception):
#         contract.update_whitelist_amounts(to_whitelist, amount, sender=deployer)

# def test_node_sale(contract, deployer):
#     to = accounts[7]
#     count = 10
#     nonce = 1
#     contract.activate_wallet(b'\x01' * 32, sender=to)
#     contract.node_sale(to, count, nonce, sender=deployer)
#     assert contract.nonce(nonce) > 0

# def test_node_sale_invalid_nonce(contract, deployer):
#     to = accounts[7]
#     count = 10
#     nonce = 1
#     contract.activate_wallet(b'\x01' * 32, sender=to)
#     contract.node_sale(to, count, nonce, sender=deployer)
#     with pytest.raises(Exception):
#         contract.node_sale(to, count, nonce, sender=deployer)

# def test_redeem_from_whitelist(contract, admin, deployer):
#     to = accounts[8]
#     count = 5
#     nonce = 2
#     contract.activate_wallet(b'\x01' * 32, sender=to)
#     contract.update_whitelist_amounts(to, 10, sender=admin)
#     contract.redeem_from_whitelist(to, count, nonce, sender=deployer)
#     assert contract.whitelist_amounts(to) == 5

# def test_redeem_from_whitelist_invalid_amount(contract, admin, deployer):
#     to = accounts[8]
#     count = 5
#     nonce = 2
#     contract.activate_wallet(b'\x01' * 32, sender=to)
#     contract.update_whitelist_amounts(to, 4, sender=admin)
#     with pytest.raises(Exception):
#         contract.redeem_from_whitelist(to, count, nonce, sender=deployer)

# def test_set_fee_receiver(contract, admin):
#     new_fee_receiver = accounts[9]
#     contract.set_fee_receiver(new_fee_receiver, sender=admin)
#     assert contract.fee_receiver() == new_fee_receiver

# def test_set_fee_receiver_non_admin(contract, deployer):
#     new_fee_receiver = accounts[9]
#     with pytest.raises(Exception):
#         contract.set_fee_receiver(new_fee_receiver, sender=deployer)

# def test_set_funds_receiver(contract, admin):
#     new_funds_receiver = accounts[10]
#     contract.set_funds_receiver(new_funds_receiver, sender=admin)
#     assert contract.funds_receiver() == new_funds_receiver

# def test_set_funds_receiver_non_admin(contract, deployer):
#     new_funds_receiver = accounts[10]
#     with pytest.raises(Exception):
#         contract.set_funds_receiver(new_funds_receiver, sender=deployer)

# def test_set_paloma(contract, compass):
#     paloma = b'\x02' * 32
#     contract.set_paloma(sender=compass, data=paloma)
#     assert contract.paloma() == paloma

# def test_set_paloma_invalid_sender(contract, deployer):
#     paloma = b'\x02' * 32
#     with pytest.raises(Exception):
#         contract.set_paloma(sender=deployer, data=paloma)

# def test_set_processing_fee(contract, admin):
#     new_processing_fee = 200
#     new_subscription_fee = 300
#     contract.set_processing_fee(new_processing_fee, new_subscription_fee, sender=admin)
#     assert contract.processing_fee() == new_processing_fee
#     assert contract.subscription_fee() == new_subscription_fee

# def test_set_processing_fee_non_admin(contract, deployer):
#     new_processing_fee = 200
#     new_subscription_fee = 300
#     with pytest.raises(Exception):
#         contract.set_processing_fee(new_processing_fee, new_subscription_fee, sender=deployer)

# def test_set_referral_percentages(contract, admin):
#     new_discount_percentage = 600
#     new_reward_percentage = 700
#     contract.set_referral_percentages(new_discount_percentage, new_reward_percentage, sender=admin)
#     assert contract.referral_discount_percentage() == new_discount_percentage
#     assert contract.referral_reward_percentage() == new_reward_percentage

# def test_set_referral_percentages_non_admin(contract, deployer):
#     new_discount_percentage = 600
#     new_reward_percentage = 700
#     with pytest.raises(Exception):
#         contract.set_referral_percentages(new_discount_percentage, new_reward_percentage, sender=deployer)

# def test_set_start_end_timestamp(contract, admin):
#     new_start_timestamp = 1000
#     new_end_timestamp = 2000
#     contract.set_start_end_timestamp(new_start_timestamp, new_end_timestamp, sender=admin)
#     assert contract.start_timestamp() == new_start_timestamp
#     assert contract.end_timestamp() == new_end_timestamp

# def test_set_start_end_timestamp_non_admin(contract, deployer):
#     new_start_timestamp = 1000
#     new_end_timestamp = 2000
#     with pytest.raises(Exception):
#         contract.set_start_end_timestamp(new_start_timestamp, new_end_timestamp, sender=deployer)

# def test_update_admin(contract, admin):
#     new_admin = accounts[11]
#     contract.update_admin(new_admin, sender=admin)
#     assert contract.admin() == new_admin

# def test_update_admin_non_admin(contract, deployer):
#     new_admin = accounts[11]
#     with pytest.raises(Exception):
#         contract.update_admin(new_admin, sender=deployer)

# def test_update_compass(contract, compass):
#     new_compass = accounts[12]
#     contract.update_compass(new_compass, sender=compass)
#     assert contract.compass() == new_compass

# def test_update_compass_invalid_sender(contract, deployer):
#     new_compass = accounts[12]
#     with pytest.raises(Exception):
#         contract.update_compass(new_compass, sender=deployer)