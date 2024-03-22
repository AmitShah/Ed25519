import { ethers } from "hardhat";
import chai from "chai";

import { HashCastGateway, Karma } from '../typechain';
import { verify } from "crypto";
import { BytesLike, Wallet } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Connection, PublicKey, clusterApiUrl, RpcResponseAndContext, SignatureResult, Keypair, Account, PUBLIC_KEY_LENGTH} from "@solana/web3.js";
import {ed25519} from '@noble/curves/ed25519';
import dotenv from 'dotenv'; 
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

dotenv.config()

const { expect } = chai;

const domain = {
    name: 'HashCastGateway',
    version: '1.0.0',
    chainId: 31337,
    verifyingContract: ethers.constants.AddressZero
  }
  
  const types = {
    Claim: [{
        name: 'from',
        type: 'address'
      },
      {
          name:'nonce',
          type: 'uint256'
      }
    ]
  }

describe('HashCastGateway', () => {
    let gateway: HashCastGateway
    let karma : Karma
    let owner: SignerWithAddress
    before('deploy Ed25519', async () => {
        const ed25519Factory = await ethers.getContractFactory('HashCastGateway')
        const karmaFactory = await ethers.getContractFactory('Karma')

        let signers = await ethers.getSigners();
        owner = signers[0];
        karma = (await karmaFactory.deploy(owner.address, "Karma","$KARMA")) as Karma;
        gateway = (await ed25519Factory.deploy(karma.address)) as HashCastGateway
        await karma.setOwner(gateway.address);

    })

    it(`can verify on-chain`, async ()=>{
        
        const sk = ed25519.utils.randomPrivateKey();
        const pk = ethers.utils.hexlify(ed25519.getPublicKey(sk));
        console.log("pk:",pk);

        // const publicKey = ethers.utils.hexlify(Buffer.from(kp.publicKey.toBytes()));
        // console.log("public key:",publicKey);
        domain.verifyingContract = gateway.address;
        const vaddress = await gateway.getVirtualAddress(pk);
        const nonce = await gateway.nonces(vaddress);
        console.log("vaddress:",vaddress);
        console.log("nonce:",nonce);
        const structHash = ethers.utils._TypedDataEncoder.hash(domain, types, {from:vaddress,nonce:nonce})
        console.log("structHash:",structHash.slice(2,));
        const signature = ethers.utils.hexlify(ed25519.sign(structHash.slice(2,),sk));
        
        console.log("signature:",signature);
        const [r, s] = [signature.substring(2, 66), signature.substring(66)];
        const claimRequest = {
          pubkey:pk,
          r:`0x${r}`,
          s:`0x${s}`
        };
        const gasLimit = await gateway.estimateGas.claim(claimRequest);
        console.log("gasLimit:",gasLimit);
        const tx = await gateway.claim(claimRequest,{gasLimit:gasLimit}); 
        
        console.log(tx) ;          
    })
  
})