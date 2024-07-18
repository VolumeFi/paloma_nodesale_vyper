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
    _from: address
    _to: address
    _token_id: uint256

event Approval: 
    _owner: address
    _approved: address
    _token_id: uint256

event ApprovalForAll: 
    _owner: address
    _operator: address
    _approved: bool

event SetPaloma:
    paloma: bytes32

event UpdateCompass:
    old_compass: address
    new_compass: address

# Storage
token_owner: public(HashMap(uint256, address))
token_approvals: public(HashMap(uint256, address))
operator_approvals: public(HashMap(address, HashMap(address, bool)))
token_URIs: public(HashMap(uint256, String))
total_supply: public(uint256)
paloma: public(bytes32)
compass: public(address)

# Constructor
@external
@deploy
def __init__(_compass: address):
    self.total_supply = 0
    self.compass = _compass
    log UpdateCompass(empty(address), _compass)

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

# Minting
@external
def mint(_to: address, _token_id: uint256, _uri: String):
    self._paloma_check()
    assert _token_id not in self.token_owner, "Token already exists"
    self.token_owner[_token_id] = _to
    self.token_owner[_token_id] = _uri
    self.total_supply += 1
    log Transfer(ZERO_ADDRESS, _to, _token_id)

# ERC721 Interface
@view
@external
def owner_of(_token_id: uint256) -> address:
    return self.token_owner[_token_id]

@view
@external
def balance_of(_owner: address) -> uint256:
    _balance: uint256 = 0
    _token_owner: address = self.token_owner
    for _token_id in _token_owner:
        if _token_owner[_token_id] == _owner:
            _balance += 1
    return _balance

@external
def transfer_from(_from: address, _to: address, _token_id: uint256):
    # assert self.token_owner[_token_id] == _from, "Not the owner"
    # assert _to != ZERO_ADDRESS, "Cannot transfer to zero address"
    # self.token_owner[_token_id] = _to
    # log Transfer(_from, _to, _token_id)
    pass

@external
def approve(_approved: address, _token_id: uint256):
    assert self.token_owner[_token_id] != ZERO_ADDRESS, "Token does not exist"
    self.token_approvals[_token_id] = _approved
    log Approval(self.token_owner[_token_id], _approved, _token_id)

@view
@external
def get_approved(_token_id: uint256) -> address:
    return self.token_approvals[_token_id]

@external
def set_approval_for_all(_operator: address, _approved: bool):
    self.operator_approvals[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

@view
@external
def is_approved_for_all(_owner: address, _operator: address) -> bool:
    return self.operator_approvals[_owner][_operator]

@external
def safe_transfer_from(_from: address, _to: address, _token_id: uint256):
    self.transferFrom(_from, _to, _token_id)

@external
def safe_transfer_from(_from: address, _to: address, _token_id: uint256, _data: bytes):
    self.transferFrom(_from, _to, _token_id)

@external
@payable
def __default__():
    pass
