from ape import accounts, project, networks

def main():
    # ARB
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        blueprint = "0xffD622Ec376f367f2D7CDCA02964E7eF1Cc77465"
        compass = "0x3c1864a873879139C1BD87c7D95c4e475A91d19C"
        nodesale = "0xe649F2A20e6563aE3DD60a1e7A5e899C4ef0aeE9"

        factory = project.Factory.deploy(blueprint, compass, nodesale, sender=acct)
        print(factory)
