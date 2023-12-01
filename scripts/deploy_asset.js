const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");

async function main(){
    const Assets = await ethers.getContractFactory("contracts/Assets.sol:Assets");
    const assets = await Assets.deploy("Heroes", "HE")
    await assets.deployed(); 
    console.log("Assets deployed to: ",assets.address)
}

main()