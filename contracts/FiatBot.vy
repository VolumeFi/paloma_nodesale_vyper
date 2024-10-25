#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Paloma Node Sale FiatBot Contract
@license    Apache 2.0
@author     Volume.finance
"""
interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable

interface PalomaNodeSale:
    def pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32): nonpayable
    def activate_wallet(_paloma: bytes32, _purchased_in_v1: bool): nonpayable

interface Factory:
    def nodesale() -> address: view

event ActivatedFiat:
    sender: indexed(address)
    paloma: bytes32

event PurchasedFiat:
    buyer: indexed(address)
    token_in: address
    fund_usd_amount: uint256
    node_count: uint256
    promo_code: bytes32

event Refund:
    recipient: indexed(address)
    token: address
    amount: uint256

FACTORY: public(immutable(address))

@deploy
def __init__():
    FACTORY = msg.sender

@external
@nonreentrant
def pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32):
    self._factory_check()
    _nodesale: address = staticcall Factory(FACTORY).nodesale()
    assert extcall ERC20(_token_in).approve(_nodesale, _estimated_amount_in, default_return_value=True), "Failed approve"
    extcall PalomaNodeSale(_nodesale).pay_for_token(_token_in, _estimated_amount_in, _estimated_node_count, _total_cost, _promo_code, _path, _enhanced, _subscription_month, _own_promo_code)
    log PurchasedFiat(self, _token_in, _total_cost, _estimated_node_count, _promo_code)

@external
def activate_wallet(_paloma: bytes32, _purchased_in_v1: bool):
    self._factory_check()
    _nodesale: address = staticcall Factory(FACTORY).nodesale()
    extcall PalomaNodeSale(_nodesale).activate_wallet(_paloma, _purchased_in_v1)
    log ActivatedFiat(self, _paloma)

@external
@nonreentrant
def refund(_recipient: address, _token: address, _amount: uint256):
    self._factory_check()
    if _token == empty(address):
        send(_recipient, _amount)
    else:
        assert extcall ERC20(_token).transfer(_recipient, _amount, default_return_value=True), "Failed transfer"
    log Refund(_recipient, _token, _amount)

@internal
def _factory_check():
    assert msg.sender == FACTORY, "not factory"

@external
@payable
def __default__():
    pass