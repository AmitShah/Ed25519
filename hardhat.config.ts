import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import { HardhatUserConfig } from 'hardhat/types'
import "hardhat-gas-reporter"

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [{ version: '0.8.24', settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      },
     } }],
    
  },
  networks: {
    hardhat: {
      //allowUnlimitedContractSize: true,
    },
  },
}

export default config
