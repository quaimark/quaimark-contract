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
    hydra1: {
       url: `${process.env.HYDRA1}`,
       accounts: [process.env.PRIVKEY],
       chainId: 9000, // local chainId
    },
    hydra2: {
      url: `${process.env.HYDRA2}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    hydra3: {
      url: `${process.env.HYDRA3}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    cyprus1: {
      url: `${process.env.CYPRUS1}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    cyprus2: {
      url: `${process.env.CYPRUS2}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    cyprus3: {
      url: `${process.env.CYPRUS3}`,
      accounts: [process.env.CYPRUS3PK],
      chainId: 9000, // local chainId
    },
    paxos1: {
      url: `${process.env.PAXOS1}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    paxos2: {
      url: `${process.env.PAXOS2}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    paxos3: {
      url: `${process.env.PAXOS3}`,
      accounts: [process.env.PRIVKEY],
      chainId: 9000, // local chainId
    },
    mumbai: {
      url: "https://polygon-mumbai-bor.publicnode.com",
      accounts: [process.env.PRIVKEY]
    },
   },
 
   // include compiler version defined in your smart contract
   solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
   },
   solidityx: {
    compilerPath: "PATH_TO_SOLC_COMPILER",
    },
   paths: {
     sources: "./contracts",
     cache: "./cache",
     artifacts: "./artifacts",
   },
   mocha: {
     timeout: 20000,
   },
   etherscan : {
    apiKey: "V1BQBHGR3P1H3N45Z4BGDHQ5KUHIIAVABI"
  }
 };