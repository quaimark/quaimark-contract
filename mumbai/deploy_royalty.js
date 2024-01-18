const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");
// const CONTRACTS =  require("./contract.json")
async function main(){
    const DeMask = await ethers.getContractFactory("contracts/royalty/RoyaltyEngine.sol:RoyaltyEngine");
    // Deploy single contract
    // var network = CONTRACTS["network"] 
    const demask = await DeMask.deploy()
    await demask.deployed(); 
    //End Deploy single contract

    console.log("DeMask deployed to: ",demask.address)
}

main()