const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");
// const CONTRACTS =  require("./contract.json")
async function main(){
    const DeMask = await ethers.getContractFactory("contracts/asset/HeroAssets.sol:HeroAssets");
    // Deploy single contract
    // var network = CONTRACTS["network"] 
    const demask = await DeMask.deploy("Hero Assets", "HEA")
    await demask.deployed(); 
    //End Deploy single contract

    console.log("DeMask deployed to: ",demask.address)
}

main()