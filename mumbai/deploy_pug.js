const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");
// const CONTRACTS =  require("./contract.json")
async function main(){
    const DeMask = await ethers.getContractFactory("contracts/asset/PudgyPenguin.sol:PudgyPenguin");
    // Deploy single contract
    // var network = CONTRACTS["network"] 
    const demask = await DeMask.deploy("PudgyPenguin", "PudgyPenguin")
    await demask.deployed(); 
    //End Deploy single contract

    console.log("DeMask deployed to: ",demask.address)
}

main()