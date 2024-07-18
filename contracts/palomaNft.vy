#pragma version 0.4.0
#pragma optimize gas
#pragma evm-version cancun
"""
@title      Paloma Node Sale NFT ERC721 Contract
@license    Apache 2.0
@author     Volume.finance
"""

# Events
event Transfer: nonpayable
    _from: address
    _to: address
    _token_id: uint256

event Approval: nonpayable
    _owner: address
    _approved: address
    _token_id: uint256

event ApprovalForAll: nonpayable
    _owner: address
    _operator: address
    _approved: bool

# Storage
token_owner: public(map(uint256, address))
token_approvals: public(map(uint256, address))
operator_approvals: public(map(address, map(address, bool)))
token_URIs: public(map(uint256, string))
total_supply: public(uint256)
paloma: public(bytes32)
compass: public(address)

# Constructor
@external
def __init__():
    self.total_supply = 0

# Minting
@external
def mint(_to: address, _token_id: uint256, _uri: string):
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
    balance: uint256 = 0
    for tokenId in self.token_owner:
        if self.token_owner[tokenId] == _owner:
            balance += 1
    return balance

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