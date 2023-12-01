/**
 * @type import('hardhat/config').HardhatUserConfig
 */

//  require('@nomicfoundation/hardhat-toolbox');
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require('hardhat-abi-exporter');

 const dotenv = require('dotenv');
 dotenv.config({ path: '.env' });
 
 module.exports = {
   defaultNetwork: "local",
   networks: {
     // testnet

     // local
     local: {
       url: `${process.env.RPCURL}`,
       accounts: [process.env.PRIVKEY],
       chainId: 9000, // local chainId
     },
   },
 
   // include compiler version defined in your smart contract
   solidity: {
     compilers: [
       {
         version: '0.8.9',
       },
     ],
   },
 
   paths: {
     sources: "./contracts",
     cache: "./cache",
     artifacts: "./artifacts",
   },
   mocha: {
     timeout: 20000,
   },
 };