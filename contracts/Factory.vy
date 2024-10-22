#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Paloma Node Sale Factory Contract
@license    Apache 2.0
@author     Volume.finance
"""
interface FiatBot:
    def pay_for_token(_token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32): nonpayable
    def activate_wallet(_paloma: bytes32): nonpayable
    def refund(_recipient: address, _token: address, _amount: uint256): nonpayable

event BotCreated:
    user_id: uint256
    bot: address

event SetPaloma:
    paloma: bytes32

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateNodeSale:
    old_nodesale: address
    new_nodesale: address

blueprint: public(address)
compass: public(address)
paloma: public(bytes32)
bot_info: public(HashMap[uint256, address])
nodesale: public(address)

@deploy
def __init__(_blueprint: address, _compass: address, _nodesale: address):
    self.blueprint = _blueprint
    self.compass = _compass
    self.nodesale = _nodesale
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)
    log UpdateNodeSale(empty(address), _nodesale)

@external
def update_blueprint(_new_blueprint: address):
    self._paloma_check()
    assert _new_blueprint != empty(address), "Invalid blueprint"
    self.blueprint = _new_blueprint
    log UpdateBlueprint(self.blueprint, _new_blueprint)

@external
def update_compass(_new_compass: address):
    self._paloma_check()
    assert _new_compass != empty(address), "Invalid compass"
    self.compass = _new_compass
    log UpdateCompass(msg.sender, _new_compass)

@external
def update_nodesale(_new_nodesale: address):
    self._paloma_check()
    assert _new_nodesale != empty(address), "Invalid nodesale"
    self.nodesale = _new_nodesale
    log UpdateNodeSale(self.nodesale, _new_nodesale)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def create_bot(_user_id: uint256):
    self._paloma_check()
    assert self.bot_info[_user_id] == empty(address), "Bot already created"
    assert _user_id > 0, "Invalid user id"
    _bot: address = create_from_blueprint(self.blueprint, code_offset=3)
    assert _bot != empty(address), "Bot creation failed"
    self.bot_info[_user_id] = _bot
    log BotCreated(_user_id, _bot)

@external
@nonreentrant
def pay_for_token(_user_id: uint256, _token_in: address, _estimated_amount_in: uint256, _estimated_node_count: uint256, _total_cost: uint256, _promo_code: bytes32, _path: Bytes[204], _enhanced: bool, _subscription_month: uint256, _own_promo_code: bytes32):
    self._paloma_check()
    assert _user_id > 0, "Invalid user id"
    assert self.bot_info[_user_id] != empty(address), "Bot not created"
    extcall FiatBot(self.bot_info[_user_id]).pay_for_token(_token_in, _estimated_amount_in, _estimated_node_count, _total_cost, _promo_code, _path, _enhanced, _subscription_month, _own_promo_code)

@external
def activate_wallet(_user_id: uint256, _paloma: bytes32):
    self._paloma_check()
    assert _user_id > 0, "Invalid user id"
    assert self.bot_info[_user_id] != empty(address), "Bot not created"
    extcall FiatBot(self.bot_info[_user_id]).activate_wallet(_paloma)

@external
def refund(_user_id: uint256, _recipient: address, _token: address, _amount: uint256):
    self._paloma_check()
    assert _user_id > 0, "Invalid user id"
    assert self.bot_info[_user_id] != empty(address), "Bot not created"
    assert _recipient != empty(address), "Invalid recipient"
    assert _amount > 0, "Invalid amount"
    extcall FiatBot(self.bot_info[_user_id]).refund(_recipient, _token, _amount)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"
