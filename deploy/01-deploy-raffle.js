const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("2")


module.exports = async function ({getNamedAccounts, deployments}){
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = network.config.chainId
    let VRFCoordinatorV2Address, subscriptionId, VRFCoordinatorV2Mock

    console.log("chainId: ", chainId )

    if(developmentChains.includes(network.name)){
         VRFCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        VRFCoordinatorV2Address = VRFCoordinatorV2Mock.address
        console.log("VRFCoordinatorV2Mock address:", VRFCoordinatorV2Address)
        const transactionResponse =  await VRFCoordinatorV2Mock.createSubscription()
        const transactionReceipt = await transactionResponse.wait(1)
        subscriptionId = transactionReceipt.events[0].args.subId

        //fund the subscription
        //you'd need link token for this on real network

        await VRFCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT)
        
    } else {
        VRFCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }
    
    const entranceFee = networkConfig[chainId]["entranceFee"]
    const gasLane = networkConfig[chainId]["gasLane"]
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"]
    const interval = networkConfig[chainId]["interval"]
    
    const args = [VRFCoordinatorV2Address,entranceFee,gasLane, subscriptionId, callbackGasLimit,interval ]
    console.log("args............",args)
    
    console.log("network.config.blockConfirmations:",  network.config.blockConfirmations)
    const raffle = await deploy("Raffle", {
        from:deployer,
        args:args,
        log:true,
        waitConfirmations:network.config.blockConfirmations || 1,
        
    })
    
    // await VRFCoordinatorV2Mock.addConsumer(subscriptionId.toNumber(), raffle.address)
    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract(
          "VRFCoordinatorV2Mock"
        );
        await vrfCoordinatorV2Mock.addConsumer(subscriptionId.toNumber(), raffle.address)
        log("adding consumer...")
        log("Consumer added!")
    }

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("verifying........")
        await verify(raffle.address, args)
    }

    log("-------------------------------------")
}

module.exports.tags = ["all", "raffle"]