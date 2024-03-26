import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import { HardhatUserConfig } from 'hardhat/types'
import "hardhat-gas-reporter"
import dotenv from "dotenv"

dotenv.config()


const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [{ version: '0.8.24', settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
      
     } }],
    
  },
  networks: {
    hardhat: {
      forking: {
        url:`https://opt-mainnet.g.alchemy.com/v2/sJqLM3VfAug0vSoR-p9V_tLFpo_2LJ8k`
      }
      //allowUnlimitedContractSize: true,
    },
    sepolia: {
      url: "https://sepolia.base.org",
      accounts: [process.env.PK as string]
    }
  },
}

export default config
