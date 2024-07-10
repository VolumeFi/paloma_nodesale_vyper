import ape
import pytest
from eth_abi import encode
from web3 import Web3

@pytest.fixture(scope="session")
def Deployer(accounts):
    return accounts[0]

@pytest.fixture(scope="session")
def Admin(accounts):
    return accounts[1]

@pytest.fixture(scope="session")
def Alice(accounts):
    return accounts[2]

@pytest.fixture(scope="session")
def Compass(accounts):
    return accounts[3]

@pytest.fixture(scope="session")
def USDT(Deployer, project):
    print(project)
    return Deployer.deploy(project.testToken, "USDT", "USDT", 6, 10000000000000)

def function_signature(str):
    return Web3.keccak(text=str)[:4]

def test_add():
    assert 1 + 1 == 2

