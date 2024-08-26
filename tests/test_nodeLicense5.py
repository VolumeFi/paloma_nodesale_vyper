import pytest
import ape
from eth_abi import encode
from web3 import Web3

@pytest.fixture(scope="session")
def deployer(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def compass(accounts):
    return accounts[1]

@pytest.fixture(scope="session")
def recipient(accounts):
    return accounts[2]

@pytest.fixture(scope="session")
def whitelistacc(accounts):
    return accounts[3]

def function_signature(str):
    return Web3.keccak(text=str)[:4]

@pytest.fixture(scope="session")
def PalomaNodeSale(deployer, compass, project):
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
        1500,
        100
    )
    funcSig = function_signature("set_paloma()")
    addPayload = encode(["bytes32"], [b'123456'])
    payload = funcSig + addPayload
    contract(sender=compass, data=payload)

    return contract

def test_paloma_node_sale(PalomaNodeSale, deployer, compass, recipient, whitelistacc, accounts, project):
    assert PalomaNodeSale.admin() == deployer
    assert PalomaNodeSale.compass() == compass
    assert PalomaNodeSale.funds_receiver() == "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"
    assert PalomaNodeSale.fee_receiver() == "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    assert PalomaNodeSale.slippage_fee_percentage() == 100

    # activate_wallet
    paloma_wcc = encode(["bytes32"], [b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xd4\x5d\x0b\xee\xea\xc4\xc2\xf2\x36\x22\x3a\x70\x27\x80\x76\x6e\xb2\x80\x03\x9c'])
    PalomaNodeSale.activate_wallet(paloma_wcc, sender=deployer)
    assert PalomaNodeSale.activates(deployer) == paloma_wcc

    # create_promo_code test
    promo_code = b'\x01' * 32
    PalomaNodeSale.create_promo_code(promo_code, recipient, sender=deployer)
    assert PalomaNodeSale.promo_codes(promo_code).recipient == recipient

    # create_promo_code_non_admin
    with ape.reverts():
        PalomaNodeSale.create_promo_code(promo_code, recipient, sender=recipient)

    # remove_promo_code
    # PalomaNodeSale.remove_promo_code(promo_code, sender=deployer)
    # assert not PalomaNodeSale.promo_codes(promo_code).active

    # # remove_promo_code_non_admin
    # with ape.reverts():
    #     PalomaNodeSale.remove_promo_code(promo_code, sender=recipient)

    # update_whitelist_amounts
    amount = 1000
    PalomaNodeSale.update_whitelist_amounts(whitelistacc, amount, sender=deployer)
    assert PalomaNodeSale.whitelist_amounts(whitelistacc) == amount

    # update_whitelist_amount_non_admin
    with ape.reverts():
        PalomaNodeSale.update_whitelist_amounts(whitelistacc, amount, sender=whitelistacc)

    # redeem_from_whitelist
    count = 1
    nonce_val = 2
    to = accounts[8]
    PalomaNodeSale.activate_wallet(b'\x01' * 32, sender=to)
    PalomaNodeSale.update_whitelist_amounts(to, 10, sender=deployer)
    assert PalomaNodeSale.whitelist_amounts(to) == 10
    func_sig = function_signature("redeem_from_whitelist(address,uint256,uint256)")
    enc_abi = encode(["(address,uint256,uint256)"], [(to.address, 1, nonce_val)])
    add_payload = encode(["bytes32"], [b'123456'])
    with ape.reverts():
        PalomaNodeSale.redeem_from_whitelist(to, count, nonce_val, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.whitelist_amounts(to) == 9

    # set fee receiver
    # new_fee_receiver = accounts[9]
    # PalomaNodeSale.set_fee_receiver(new_fee_receiver, sender=deployer)
    # assert PalomaNodeSale.fee_receiver() == new_fee_receiver
    # with ape.reverts():
    #     PalomaNodeSale.set_fee_receiver(new_fee_receiver, sender=recipient)

    # set funds receiver
    # new_funds_receiver = accounts[10]
    # PalomaNodeSale.set_funds_receiver(new_funds_receiver, sender=deployer)
    # assert PalomaNodeSale.funds_receiver() == new_funds_receiver
    # with ape.reverts():
    #     PalomaNodeSale.set_funds_receiver(new_funds_receiver, sender=recipient)

    # set processing fee
    new_processing_fee = 5000000
    new_subscription_fee = 50000000
    PalomaNodeSale.set_processing_fee(new_processing_fee, new_subscription_fee, sender=deployer)
    assert PalomaNodeSale.processing_fee() == new_processing_fee
    assert PalomaNodeSale.subscription_fee() == new_subscription_fee
    with ape.reverts():
        PalomaNodeSale.set_processing_fee(new_processing_fee, new_subscription_fee, sender=recipient)

    # set referral percentages
    new_discount_percentage = 500
    new_reward_percentage = 1500
    new_slippage_percentage = 100
    PalomaNodeSale.set_referral_percentages(new_discount_percentage, new_reward_percentage, new_slippage_percentage, sender=deployer)
    assert PalomaNodeSale.referral_discount_percentage() == new_discount_percentage
    assert PalomaNodeSale.referral_reward_percentage() == new_reward_percentage
    assert PalomaNodeSale.slippage_fee_percentage() == new_slippage_percentage
    with ape.reverts():
        PalomaNodeSale.set_referral_percentages(new_discount_percentage, new_reward_percentage, new_slippage_percentage, sender=recipient)

    # set start end timestamp
    new_start_timestamp = 1722988800
    new_end_timestamp = 1726876800
    PalomaNodeSale.set_start_end_timestamp(new_start_timestamp, new_end_timestamp, sender=deployer)
    assert PalomaNodeSale.start_timestamp() == new_start_timestamp
    assert PalomaNodeSale.end_timestamp() == new_end_timestamp
    with ape.reverts():
        PalomaNodeSale.set_start_end_timestamp(new_start_timestamp, new_end_timestamp, sender=recipient)

    # update admin
    new_admin = accounts[11]
    PalomaNodeSale.update_admin(new_admin, sender=deployer)
    assert PalomaNodeSale.admin() == new_admin
    with ape.reverts():
        PalomaNodeSale.update_admin(new_admin, sender=recipient)

    # pay for eth
    eth_amount = 10**18
    estimated_node_count = 10
    total_cost = 500000000
    promo_code = b'\x01' * 32
    
    path = b'\xaf\x88\xd0\x65\xe7\x7c\x8c\xc2\x23\x93\x27\xc5\xed\xb3\xa4\x32\x26\x8e\x58\x31\x00\x01\xf4\x82\xaf\x49\x44\x7d\x8a\x07\xe3\xbd\x95\xbd\x0d\x56\xf3\x52\x41\x52\x3f\xba\xb1'
    enhanced = True
    subscription_month = 24

    usdc = project.USDC.at("0xaf88d065e77c8cC2239327C5EDb3A432268e5831")
    weth = project.USDC.at("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1")
    pool = project.USDC.at("0xC6962004f452bE9203591991D15f6b388e09E8D0")
    usdt = project.USDC.at("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9")
    user = "0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D"

    print(weth.balanceOf(deployer))
    print(deployer.balance)
    PalomaNodeSale.pay_for_eth(estimated_node_count, total_cost, b'\x00' * 32, path, enhanced, subscription_month, sender=deployer, value=eth_amount)
    print(weth.balanceOf(deployer))
    print(deployer.balance)

    path = b'\xaf\x88\xd0\x65\xe7\x7c\x8c\xc2\x23\x93\x27\xc5\xed\xb3\xa4\x32\x26\x8e\x58\x31\x00\x00\x64\xFd\x08\x6b\xC7\xCD\x5C\x48\x1D\xCC\x9C\x85\xeb\xE4\x78\xA1\xC0\xb6\x9F\xCb\xb9'
    # pay for token
    # usdt.approve(PalomaNodeSale, 106000000, sender=user)
    usdc.approve(PalomaNodeSale, 106000000, sender=user)

    # print(usdt.balanceOf(user))
    # print(usdc.balanceOf(PalomaNodeSale))
    # print(usdt.balanceOf(PalomaNodeSale))
    # print(usdc.balanceOf("0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"))
    # print(usdc.balanceOf("0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"))
    # print(usdc.balanceOf(recipient))
    # PalomaNodeSale.pay_for_token("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", 106000000, 1, 50000000, b'\x01' * 32, path, True, 1, sender=user)
    PalomaNodeSale.pay_for_token("0xaf88d065e77c8cC2239327C5EDb3A432268e5831", 106000000, 1, 50000000, b'\x01' * 32, path, True, 1, sender=user)
    # print(usdt.balanceOf(user))
    # print(usdc.balanceOf(PalomaNodeSale))
    # print(usdt.balanceOf(PalomaNodeSale))
    # print(usdc.balanceOf("0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"))
    # print(usdc.balanceOf("0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"))
    # print(usdc.balanceOf(recipient))
    assert PalomaNodeSale.promo_codes(b'\x01' * 32).active == True
    assert PalomaNodeSale.promo_codes(b'\x01' * 32).recipient == recipient
    print(usdc.balanceOf(recipient))
    with ape.reverts():
        PalomaNodeSale.claim(sender=recipient)
        print(usdc.balanceOf(recipient))

    # refund pending amount
    print(PalomaNodeSale.pendingRecipient(user))
    print(PalomaNodeSale.pending(user, recipient))
    # PalomaNodeSale.refund_pending_amount(user, sender=new_admin)
    # print(PalomaNodeSale.pendingRecipient(user))
    # print(PalomaNodeSale.pending(user, recipient))

    # node_sale
    count = 10
    nonce_val = 1
    PalomaNodeSale.activate_wallet(b'\x02' * 32, sender=user)
    func_sig = function_signature("node_sale(address,uint256,uint256)")
    enc_abi = encode(["(address,uint256,uint256)"], [(user, count, nonce_val)])
    add_payload = encode(["bytes32"], [b'123456'])
    with ape.reverts():
        PalomaNodeSale.node_sale(user, count, nonce_val, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.nonces(1) > 0
    assert PalomaNodeSale.nonces(2) > 0
    assert PalomaNodeSale.activates(user) == b'\x00' * 32
    assert PalomaNodeSale.activates(to) == b'\x00' * 32
    with ape.reverts():
        PalomaNodeSale(sender=compass, data=payload)
    
    print(usdc.balanceOf(recipient))
    PalomaNodeSale.claim(sender=recipient)
    print(usdc.balanceOf(recipient))

    with ape.reverts():
        PalomaNodeSale.activate_wallet(b'\x01' * 32, sender=user)

    
