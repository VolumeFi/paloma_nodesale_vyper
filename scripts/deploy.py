from ape import accounts, project, networks

def main():
    start_timestamp = 1724371200        # Aug 23 gmt+0
    end_timestamp = 1751328000          # Dec 31 gmt+0
    processing_fee = 5000000            # 5 USDC
    subscription_fee = 50000000         # 50 USDC per month
    parent_fee_percentage = 100         # 1%
    default_referral_discount_percentage = 500  # 5%
    default_referral_reward_percentage = 1000   # 10%
    slippage_fee_percentage = 50        # 0.5%
    grains_per_node = 5000
    admin = "0x693Cb40FbC5eA369348EF0D467De5dAC46d6DD8d"            # admin
    fee_receiver = "0xADC5ee42cbF40CD4ae29bDa773F468A659983B74"
    
    # ARB 
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0x3c1864a873879139C1BD87c7D95c4e475A91d19C"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
        reward_token = "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"     # USDC
        fund_receiver = "0x460FcDf30bc935c8a3179AF4dE8a40b635a53294"    # Fund
        v1_contract = "0x249cE7e8c5A0f7300f9c45Af70c644b39dABa4dB"
        
        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee, 
            subscription_fee, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node,
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)
    
    # ETH
    with networks.parse_network_choice("ethereum:mainnet") as provider:
        acct = accounts.load("Deployer")
        compass = "0x71956340a586db3afD10C2645Dbe8d065dD79AC8"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
        reward_token = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"     # USDC 
        fund_receiver = "0x3E1912cb4A2fF0aF856B17dCAEA94976297b69a5"    # Fund
        v1_contract = "0x8050371F14Bb6E2395E936611615BE41237faF02"
        
        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee, 
            subscription_fee, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node, 
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)

    # BSC
    with networks.parse_network_choice("bsc:mainnet") as provider:
        acct = accounts.load("Deployer")
        compass = "0xEb1981B0bC9C8ED8eE5F95D5ad0494B848020413"
        swap_router = "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2"      # SWAP_ROUTER_02
        reward_token = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"     # USDC
        fund_receiver = "0x58b604EfAC11396A3F11e948A650f26ab5485E3d"    # Fund
        v1_contract = "0x2f78AfAdD7E58052c4a8789dc01A1eD49848cc0C"
        
        processing_fee_1 = 5000000000000000000            # 5 USDC
        subscription_fee_1 = 50000000000000000000         # 50 USDC per month

        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee_1, 
            subscription_fee_1, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node,
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)

    # MATIC
    with networks.parse_network_choice("polygon:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0x6aC565F13FEE0f5D44D76036Aa6461Fb1A9D8b4B"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
        reward_token = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"     # USDC
        fund_receiver = "0xCd7aCE03416089FEae6e11245f1c74593Da10a4B"    # Fund
        v1_contract = "0x496C48d24a33B1Fd45782537eBd42157Bf265703"
        
        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee, 
            subscription_fee, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node, 
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)

    # BASE 
    with networks.parse_network_choice("base:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0x105230D0ee3ADB4E07654Eb35ad88E32Be791814"
        swap_router = "0x2626664c2603336E57B271c5C0b26F421741e481"      # SWAP_ROUTER_02
        reward_token = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"     # USDC
        fund_receiver = "0x782376edF93423DF3FB7b1C651D7Ab7303dEA615"    # Fund
        v1_contract = "0x2f78AfAdD7E58052c4a8789dc01A1eD49848cc0C"
        
        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee, 
            subscription_fee, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node, 
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)

    # OP
    with networks.parse_network_choice("optimism:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        compass = "0xa41886cFA7f2d8cE8Dc15670DDD25eD890822856"
        swap_router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"      # SWAP_ROUTER_02
        reward_token = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"     # USDC
        fund_receiver = "0x2DEAE8EdBA2A1B3Dc863Fa3864F41E2a56768Ee8"    # Fund
        v1_contract = "0x496C48d24a33B1Fd45782537eBd42157Bf265703"
        
        palomaNodeSale = project.PalomaNodeSale.deploy(
            compass, 
            swap_router, 
            reward_token, 
            admin, 
            fund_receiver, 
            fee_receiver, 
            start_timestamp, 
            end_timestamp, 
            processing_fee, 
            subscription_fee, 
            slippage_fee_percentage, 
            parent_fee_percentage, 
            default_referral_discount_percentage, 
            default_referral_reward_percentage, 
            grains_per_node, 
            v1_contract,
            sender=acct
        )
        print(palomaNodeSale)