const {developmentChains} = require("../helper-hardhat-config")

const { network } = require("hardhat");

module.exports = async function ({getNamedAccounts, deployments}) {
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts();
    const chainId = network.config.chainId

    if(developmentChains.includes(chainId)) {
        log("local network detected! deploying mocks.............")
    }
}