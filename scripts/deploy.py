from ape import accounts, project, networks

def main():
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = ""
        swap_router = ""
        reward_token = ""
        admin = ""
        fund_receiver = ""
        fee_receiver = ""
        start_timestamp = 1723633200
        end_timestamp = 1726225200
        processing_fee = 5000000