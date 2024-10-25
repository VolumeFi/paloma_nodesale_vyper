import pytest
import ape
from eth_abi import encode
from web3 import Web3
from typing import Union

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
        1735603200,
        5000000,
        50000000,
        50,
        100,
        500,
        1000,
        17000,
    )
    funcSig = function_signature("set_paloma()")
    addPayload = encode(["bytes32"], [b'123456'])
    payload = funcSig + addPayload
    contract(sender=compass, data=payload)

    return contract

def get_blueprint_initcode(initcode: Union[str, bytes]):
    if isinstance(initcode, str):
        initcode = bytes.fromhex(initcode[2:])
    initcode = b"\xfe\x71\x00" + initcode
    initcode = (
        b"\x61" + len(initcode).to_bytes(2, "big") +
        b"\x3d\x81\x60\x0a\x3d\x39\xf3" + initcode
    )
    return initcode

@pytest.fixture(scope="session")
def blueprint(deployer, project):
    # contract = deployer.deploy(
    #     project.FiatBot,
    #     PalomaNodeSale
    # )
    initcode = get_blueprint_initcode(project.FiatBot.contract_type.deployment_bytecode.bytecode)
    max_base_fee = 100
    kw = {
        'max_fee': max_base_fee,
        'max_priority_fee': min(int(0.01e9), max_base_fee)}
    tx = project.provider.network.ecosystem.create_transaction(
        chain_id=project.provider.chain_id,
        data=initcode,
        nonce=deployer.nonce,
        **kw
    )
    receipt = deployer.call(tx)
    return receipt.contract_address

@pytest.fixture(scope="session")
def factory(deployer, blueprint, compass, PalomaNodeSale, project):
    contract = deployer.deploy(
        project.Factory,
        blueprint,
        compass,
        PalomaNodeSale
    )

    funcSig = function_signature("set_paloma()")
    addPayload = encode(["bytes32"], [b'123456'])
    payload = funcSig + addPayload
    contract(sender=compass, data=payload)

    return contract

def test_paloma_node_sale(PalomaNodeSale, blueprint, factory, deployer, compass, recipient, whitelistacc, accounts, project):
    assert factory.blueprint() == blueprint
    assert PalomaNodeSale.admin() == deployer
    assert PalomaNodeSale.compass() == compass
    assert PalomaNodeSale.funds_receiver() == "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"
    assert PalomaNodeSale.fee_receiver() == "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    assert PalomaNodeSale.slippage_fee_percentage() == 50
    assert PalomaNodeSale.parent_fee_percentage() == 100
    assert PalomaNodeSale.default_discount_percentage() == 500
    assert PalomaNodeSale.default_reward_percentage() == 1000

    # activate_wallet
    paloma_wcc = encode(["bytes32"], [b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xd4\x5d\x0b\xee\xea\xc4\xc2\xf2\x36\x22\x3a\x70\x27\x80\x76\x6e\xb2\x80\x03\x9c'])
    PalomaNodeSale.activate_wallet(paloma_wcc, sender=deployer)
    assert PalomaNodeSale.activates(deployer) == paloma_wcc

    # create_promo_code test
    promo_code = b'\x01' * 32
    empty_promo_code = b'\x00' * 32
    parent1_promo_code = b'\x02' * 32
    parent2_promo_code = b'\x03' * 32
    parent3_promo_code = b'\x04' * 32
    parent4_promo_code = b'\x05' * 32
    referral_discount_percentage = 500
    referral_reward_percentage = 1000
    PalomaNodeSale.create_promo_code(promo_code, recipient, empty_promo_code, referral_discount_percentage, referral_reward_percentage, sender=deployer)
    PalomaNodeSale.create_promo_code(parent1_promo_code, whitelistacc, promo_code, referral_discount_percentage, referral_reward_percentage, sender=deployer)
    PalomaNodeSale.create_promo_code(parent2_promo_code, accounts[4], parent1_promo_code, referral_discount_percentage, referral_reward_percentage, sender=deployer)
    PalomaNodeSale.create_promo_code(parent3_promo_code, accounts[5], parent2_promo_code, referral_discount_percentage, referral_reward_percentage, sender=deployer)
    PalomaNodeSale.create_promo_code(parent4_promo_code, accounts[6], parent3_promo_code, referral_discount_percentage, referral_reward_percentage, sender=deployer)
    assert PalomaNodeSale.promo_codes(promo_code).recipient == recipient
    
    # create_promo_code_non_admin
    with ape.reverts():
        PalomaNodeSale.create_promo_code(promo_code, recipient, empty_promo_code, referral_discount_percentage, referral_reward_percentage, sender=recipient)

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
    func_sig = function_signature("redeem_from_whitelist(address,uint256,uint256,bytes32)")
    enc_abi = encode(["address","uint256","uint256","bytes32"], [to.address, 1, nonce_val, b'\x01' * 32])
    add_payload = encode(["bytes32"], [b'123456'])
    with ape.reverts():
        PalomaNodeSale.redeem_from_whitelist(to, count, nonce_val, b'\x01' * 32, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.whitelist_amounts(to) == 9

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
    new_reward_percentage = 1000
    PalomaNodeSale.set_discount_reward_percentage(new_discount_percentage, new_reward_percentage, sender=deployer)
    assert PalomaNodeSale.default_discount_percentage() == new_discount_percentage
    assert PalomaNodeSale.default_reward_percentage() == new_reward_percentage
    with ape.reverts():
        PalomaNodeSale.set_discount_reward_percentage(new_discount_percentage, new_reward_percentage, sender=recipient)
    new_slippage_percentage = 100
    PalomaNodeSale.set_slippage_fee_percentage(new_slippage_percentage, sender=deployer)
    assert PalomaNodeSale.slippage_fee_percentage() == new_slippage_percentage
    with ape.reverts():
        PalomaNodeSale.set_slippage_fee_percentage(new_slippage_percentage, sender=recipient)

    # set start end timestamp
    new_start_timestamp = 1722988800
    new_end_timestamp = 1735603199
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
    own_promo_code = b'TEST1234'
    own_promo_code1 = b'TEST2345'
    usdc = project.USDC.at("0xaf88d065e77c8cC2239327C5EDb3A432268e5831")
    weth = project.USDC.at("0x82aF49447D8a07e3bd95BD0d56f35241523fBab1")
    pool = project.USDC.at("0xC6962004f452bE9203591991D15f6b388e09E8D0")
    usdt = project.USDC.at("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9")
    user = "0xB38e8c17e38363aF6EbdCb3dAE12e0243582891D"

    before = usdc.balanceOf(PalomaNodeSale.funds_receiver())
    print(weth.balanceOf(deployer))
    print(deployer.balance)
    PalomaNodeSale.pay_for_eth(estimated_node_count, total_cost, promo_code, path, enhanced, subscription_month, own_promo_code, sender=deployer, value=eth_amount)
    print(weth.balanceOf(deployer))
    print(deployer.balance)

    assert usdc.balanceOf(PalomaNodeSale.funds_receiver()) == before + 450000000

    path = b'\xaf\x88\xd0\x65\xe7\x7c\x8c\xc2\x23\x93\x27\xc5\xed\xb3\xa4\x32\x26\x8e\x58\x31\x00\x00\x64\xFd\x08\x6b\xC7\xCD\x5C\x48\x1D\xCC\x9C\x85\xeb\xE4\x78\xA1\xC0\xb6\x9F\xCb\xb9'
    # pay for token
    usdc.approve(PalomaNodeSale, 106000000, sender=user)

    before = usdc.balanceOf(PalomaNodeSale.funds_receiver())
    PalomaNodeSale.pay_for_token("0xaf88d065e77c8cC2239327C5EDb3A432268e5831", 105500000, 1, 50000000, own_promo_code, path, True, 1, own_promo_code1, sender=user)
    assert usdc.balanceOf(PalomaNodeSale.funds_receiver()) == before + 45000000
    assert PalomaNodeSale.promo_codes(b'\x01' * 32).active == True
    assert PalomaNodeSale.promo_codes(b'\x01' * 32).recipient == recipient
    print(usdc.balanceOf(recipient))
    with ape.reverts():
        PalomaNodeSale.claim(sender=recipient)
        print(usdc.balanceOf(recipient))

    # refund pending amount
    print(PalomaNodeSale.pending_recipient(deployer))
    assert PalomaNodeSale.pending_recipient(deployer) == recipient
    print(PalomaNodeSale.pending(deployer, recipient))
    assert PalomaNodeSale.pending(deployer, recipient) == 50000000
    print(PalomaNodeSale.pending_recipient(user))
    assert PalomaNodeSale.pending_recipient(user) == deployer
    print(PalomaNodeSale.pending(user, deployer))
    assert PalomaNodeSale.pending(user, deployer) == 4500000
    print(PalomaNodeSale.pending_parent1_recipient(user))
    assert PalomaNodeSale.pending_parent1_recipient(user) == recipient
    print(PalomaNodeSale.pending(user, recipient))
    assert PalomaNodeSale.pending(user, recipient) == 500000

    # node_sale
    count = 10
    nonce_val = 1
    PalomaNodeSale.activate_wallet(b'\x02' * 32, sender=user)
    func_sig = function_signature("node_sale(address,uint256,uint256,bytes32)")
    enc_abi = encode(["address", "uint256", "uint256", "bytes32"], [user, count, nonce_val, b'\x02' * 32])
    add_payload = encode(["bytes32"], [b'123456'])
    with ape.reverts():
        PalomaNodeSale.node_sale(user, count, nonce_val, b'\x02' * 32, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.nonces(1) > 0
    assert PalomaNodeSale.nonces(2) > 0
    func_sig = function_signature("update_paloma_history(address)")
    enc_abi = encode(["address"], [user])
    with ape.reverts():
        PalomaNodeSale.update_paloma_history(user, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.activates(user) == b'\x00' * 32
    enc_abi = encode(["address"], ["0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"])
    with ape.reverts():
        PalomaNodeSale.update_paloma_history(to, sender=compass)
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.activates(to) == b'\x00' * 32
    with ape.reverts():
        PalomaNodeSale(sender=compass, data=payload)
    
    print(usdc.balanceOf(recipient))
    assert PalomaNodeSale.claimable(recipient) == 500000
    PalomaNodeSale.claim(sender=recipient)
    assert PalomaNodeSale.claimable(recipient) == 0
    print(usdc.balanceOf(recipient))

    with ape.reverts():
        PalomaNodeSale.activate_wallet(b'\x01' * 32, sender=user)

    user_id = 1
    func_sig = function_signature("create_bot(uint256)")
    enc_abi = encode(["uint256"], [user_id])
    payload = func_sig + enc_abi + add_payload
    with ape.reverts():
        factory.create_bot(user_id, sender=compass)
    factory(sender=compass, data=payload)
    bot = factory.bot_info(user_id)
    usdc.transfer(bot, 1000000000, sender=user)
    assert usdc.balanceOf(bot) == 1000000000
    print(usdc.balanceOf(PalomaNodeSale))
    own_promo_code2 = b'TEST3456'
    with ape.reverts():
        factory.pay_for_token(user_id, "0xaf88d065e77c8cC2239327C5EDb3A432268e5831", 55500000, 1, 50000000, own_promo_code1, path, False, 0, own_promo_code2, sender=compass)
    func_sig = function_signature("pay_for_token(uint256,address,uint256,uint256,uint256,bytes32,bytes,bool,uint256,bytes32)")
    enc_abi = encode(["uint256","address","uint256","uint256","uint256","bytes32","bytes","bool","uint256","bytes32"], [user_id, "0xaf88d065e77c8cC2239327C5EDb3A432268e5831", 115500000, 1, 50000000, own_promo_code1, b'', True, 1, own_promo_code2])
    payload = func_sig + enc_abi + add_payload
    factory(sender=compass, data=payload)
    assert usdc.balanceOf(bot) == 894500000
    with ape.reverts():
        factory.activate_wallet(user_id, b'\x03' * 32, sender=compass)
    func_sig = function_signature("activate_wallet(uint256,bytes32)")
    enc_abi = encode(["uint256","bytes32"], [user_id, b'\x03' * 32])
    payload = func_sig + enc_abi + add_payload
    factory(sender=compass, data=payload)
    assert PalomaNodeSale.activates(bot) == b'\x03' * 32
    with ape.reverts():
        PalomaNodeSale.node_sale(bot, 1, 3, b'\x03' * 32, sender=compass)
    func_sig = function_signature("node_sale(address,uint256,uint256,bytes32)")
    enc_abi = encode(["address","uint256","uint256","bytes32"], [bot, 1, 3, b'\x03' * 32])
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.nonces(3) > 0
    func_sig = function_signature("update_paloma_history(address)")
    enc_abi = encode(["address"], [bot])
    payload = func_sig + enc_abi + add_payload
    PalomaNodeSale(sender=compass, data=payload)
    assert PalomaNodeSale.activates(bot) == b'\x00' * 32
    with ape.reverts():
        factory.refund(user_id, user, usdc, usdc.balanceOf(bot), sender=compass)
    func_sig = function_signature("refund(uint256,address,address,uint256)")
    enc_abi = encode(["uint256","address","address","uint256"], [user_id, user, "0xaf88d065e77c8cC2239327C5EDb3A432268e5831", usdc.balanceOf(bot)])
    payload = func_sig + enc_abi + add_payload
    factory(sender=compass, data=payload)
    assert usdc.balanceOf(bot) == 0
    
    
