from ape import accounts, project, networks

def main():
    # ARB
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        blueprint = "0xEd43D1D3991dc710400D68454E3c67c9A7C37a55"
        compass = "0x82Ed642F4067D55cE884e2823951baDfEdC89e73"
        nodesale = "0x249cE7e8c5A0f7300f9c45Af70c644b39dABa4dB"

        factory = project.Factory.deploy(blueprint, compass, nodesale, sender=acct)
        print(factory)
