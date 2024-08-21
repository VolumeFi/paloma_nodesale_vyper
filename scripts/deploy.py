from ape import accounts, project, networks

def main():
    start_timestamp = 1724371200        # Aug 23 gmt+0
    end_timestamp = 1735603200          # Dec 31 gmt+0
    processing_fee = 5000000            # 5 USDC
    subscription_fee = 50000000         # 50 USDC per month
    referral_discount_percentage = 500  # 5%
    referral_reward_percentage = 1000   # 10%
    slippage_fee_percentage = 50        # 0.5%

    # ARB
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0x1D0e77dFBDF7B8503087fDb7d631fc48CF226815"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
        reward_token = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"     # USDC
        admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
        fund_receiver = "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"    # Fund
        fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

        palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
        print(palomaNodeSale)
    
    # # ETH
    # with networks.parse_network_choice("ethereum:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = ""
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
    #     reward_token = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"     # USDC
    #     admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
    #     fund_receiver = "0x3E1912cb4A2fF0aF856B17dCAEA94976297b69a5"    # Fund
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
    #     print(palomaNodeSale)

    # # BSC
    # with networks.parse_network_choice("bsc:mainnet") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = ""
    #     swap_router = "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2"      # SWAP_ROUTER_02
    #     reward_token = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"     # USDC
    #     admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
    #     fund_receiver = "0x58b604EfAC11396A3F11e948A650f26ab5485E3d"    # Fund
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
    #     print(palomaNodeSale)

    # # MATIC
    # with networks.parse_network_choice("polygon:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = ""
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
    #     reward_token = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"     # USDC
    #     admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
    #     fund_receiver = "0xCd7aCE03416089FEae6e11245f1c74593Da10a4B"    # Fund
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
    #     print(palomaNodeSale)

    # BASE
    with networks.parse_network_choice("base:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0xF8bacd79456e20e661Dd47FF0137Bbc1929F60c8"
        swap_router = "0x2626664c2603336E57B271c5C0b26F421741e481"      # SWAP_ROUTER_02
        reward_token = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"     # USDC
        admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
        fund_receiver = "0x782376edF93423DF3FB7b1C651D7Ab7303dEA615"    # Fund
        fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

        palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
        print(palomaNodeSale)

    # # OP
    # with networks.parse_network_choice("optimism:mainnet:alchemy") as provider:
    #     acct = accounts.load("Deployer")
    #     compass = ""
    #     swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
    #     reward_token = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"     # USDC
    #     admin = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"            # admin
    #     fund_receiver = "0x2DEAE8EdBA2A1B3Dc863Fa3864F41E2a56768Ee8"    # Fund
    #     fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"

    #     palomaNodeSale = project.PalomaNodeSale.deploy(compass, swap_router, reward_token, admin, fund_receiver, fee_receiver, start_timestamp, end_timestamp, processing_fee, subscription_fee, referral_discount_percentage, referral_reward_percentage, slippage_fee_percentage, sender=acct)
    #     print(palomaNodeSale)