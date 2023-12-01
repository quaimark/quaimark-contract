const { ethers , upgrades } = require("hardhat");
// const hne = require("hardhat");

async function main(){
    const OverMint = await ethers.getContractFactory("contracts/OverMintProxy.sol:OverMint");
    // const overMint = await upgrades.upgradeProxy("0xf3eB9c421C4e153756239ddffbDcb7285a6b9170", OverMint, { initializer: 'initialize' })
    const overMint = await upgrades.deployProxy( OverMint, { initializer: 'initialize' });
    console.log("OverMint deployed to: ",overMint.address)
}

main()