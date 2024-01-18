const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");
const CONTRACTS =  require("../scripts/contract.json")
async function main(){
    const DeMask = await ethers.getContractFactory("contracts/market/QuaiMarkV1.sol:QuaiMarkV1");
    // Deploy single contract
    var weth = CONTRACTS["mumbai"]["weth"]
    var roy = CONTRACTS["mumbai"]["royalty"] 
    const demask = await DeMask.deploy(weth, roy)
    await demask.deployed(); 
    //End Deploy single contract

    console.log("DeMask deployed to: ",demask.address)
}

main()