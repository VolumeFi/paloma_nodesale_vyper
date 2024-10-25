from ape import accounts, project, networks

def main():
    # ARB
    with networks.parse_network_choice("arbitrum:mainnet:alchemy") as provider:
        acct = accounts.load("Deployer")
        blueprint = "0xffD622Ec376f367f2D7CDCA02964E7eF1Cc77465"
        compass = "0x82Ed642F4067D55cE884e2823951baDfEdC89e73"
        nodesale = "0xbD2c6F718Ee724884E536be3Fa6Ca5b3E0D1Be36"

        factory = project.Factory.deploy(blueprint, compass, nodesale, sender=acct)
        print(factory)
