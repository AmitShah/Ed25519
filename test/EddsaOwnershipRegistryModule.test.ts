import { ethers } from "hardhat";
import chai from "chai";

import { EddsaOwnershipRegistryModule } from '../typechain';
import { verify } from "crypto";
import { BytesLike, Wallet } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Connection, PublicKey, clusterApiUrl, RpcResponseAndContext, SignatureResult, Keypair, Account, PUBLIC_KEY_LENGTH} from "@solana/web3.js";
import {ed25519} from '@noble/curves/ed25519';
import dotenv from 'dotenv'; 
import {}
dotenv.config()
import { createECDSAOwnershipValidationModule, createSmartAccountClient } from "@biconomy/account";
import { EddsaSigner } from "./EddsaSigner.test";

const { expect } = chai;

const domain = {
    name: 'HashCastGateway',
    version: '1.0.0',
    chainId: 31337,
    verifyingContract: ethers.constants.AddressZero
  }
  
  const types = {
    Claim: [{
        name: 'address',
        type: 'bytes32'
      },
      {
          name:'nonce',
          type: 'uint256'
      }
    ]
  }

describe('EddsaOwnershipRegistryModule', () => {
    let gateway: EddsaOwnershipRegistryModule

    before('deploy Ed25519', async () => {
        const eddsaOwnershipRegistryModuleFactory = await ethers.getContractFactory('EddsaOwnershipRegistryModule')
        gateway = (await eddsaOwnershipRegistryModuleFactory.deploy()) as EddsaOwnershipRegistryModule
    })

    it(`can verify on-chain`, async ()=>{
        console.log(gateway.address)
        const signer = new EddsaSigner();
        const defaultValidationModule = await EDDSAOwnershipValidationModule.create({ signer });
        const bundlerUrl = ""
        const smartWallet = await createSmartAccountClient({
            signer,
            defaultValidationModule,
            bundlerUrl,
          });
          
          
          const setupAndEnableModuleData = await smartWallet.getSetupAndEnableModuleData(gateway.address as `0x${string}`, initData);
          expect(setupAndEnableModuleData).to.be.true;
         
        // const sk = ed25519.utils.randomPrivateKey();
        // const pk = ethers.utils.hexlify(ed25519.getPublicKey(sk));
        // console.log("pk:",pk);

        // // const publicKey = ethers.utils.hexlify(Buffer.from(kp.publicKey.toBytes()));
        // // console.log("public key:",publicKey);
        // domain.verifyingContract = gateway.address;
        // const structHash = ethers.utils._TypedDataEncoder.hash(domain, types, {address:pk,nonce:0})
        // console.log("structHash:",structHash.slice(2,));
        // // console.log("")
        // const signature = ethers.utils.hexlify(ed25519.sign(structHash.slice(2,),sk));
        
        // console.log(signature);
        // const [r, s] = [signature.substring(2, 66), signature.substring(66)];
        // const tx = await gateway.claim(pk,`0x${r}`,`0x${s}`); 
        // console.log(tx) ;          
    })
  
})