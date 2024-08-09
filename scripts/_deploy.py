from ape import accounts, project, networks

def main():
    # ARB for PalomaNodeSaleNFT.vy
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0x2E68518cC9351843d11B3F41c08a63cd5B72Eb71"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
        reward_token = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"     # USDC
        admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
        fund_receiver = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"    # temporary
        fee_receiver = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
        # start_timestamp = 1723633200
        start_timestamp = 1722498132
        end_timestamp = 1726225200
        processing_fee = 5000000

        palomaNodeSaleNFT = project.PalomaNodeSaleNFT.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
        print(palomaNodeSaleNFT)
    
    # ETH/BNB/MATIC/BLAST/BASE/OP for PalomaNodeSale.vy
    # with networks.parse_network_choice("ethereum:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0x2fE59ff4f13Ea42444B3BAB28Bdd69878d38010F"
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    #     reward_token = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"     # USDC
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)

    # with networks.parse_network_choice("bsc:mainnet") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0xb47247d125D87Cd15A69d041d009005AeC8bBf8b"
    #     swap_router = "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2"
    #     reward_token = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"     # USDC
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)

    # with networks.parse_network_choice("polygon:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0x9b9F6842Bc2814CBc63fdB0850D06F4161d9183C"
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    #     reward_token = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"     # USDC
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)

    # with networks.parse_network_choice("blast:mainnet") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0xe99716d73fcb603e10f23b1bBC1e32d29da92f65"
    #     swap_router = "0x549FEB8c9bd4c12Ad2AB27022dA12492aC452B66"
    #     reward_token = "0x4300000000000000000000000000000000000003"     # USDB
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)

    # with networks.parse_network_choice("base:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0x717c63f090AEAd8CdE9eFB0D34b0bde83F6947Fe"
    #     swap_router = "0x2626664c2603336E57B271c5C0b26F421741e481"
    #     reward_token = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"     # USDC
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)

    # with networks.parse_network_choice("optimism:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = "0x950AA3028F1A3A09D4969C3504BEc30D7ac7d6b2"
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    #     reward_token = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"     # USDC
    #     admin = "0x2175e091176F43eD55313e4Bc31FE4E94051A6fE"
    #     fund_receiver = "0x48C32baE02Dcd72e9DfE7aaDadAd52402670d4C5"    # temporary
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    #     start_timestamp = 1723633200
    #     end_timestamp = 1726225200
    #     processing_fee = 5000000

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, sender=acct)
    #     print(palomaNodeSale)