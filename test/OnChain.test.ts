import { ethers } from "hardhat";
import chai from "chai";

import { Ed25519Verify, HashCastGateway } from '../typechain';
import { verify } from "crypto";
import { BytesLike, Wallet } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";
import {ed25519} from '@noble/curves/ed25519';

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


describe('Ed25519Verify  OnChain', () => {
    let ed25519Verify: Ed25519Verify
    let gateway: HashCastGateway
    let wallet: Wallet

    before('deploy Ed25519', async () => {
        wallet = new Wallet(process.env.PK as string,new JsonRpcProvider(`https://sepolia.base.org`));
        console.log('connected:',wallet.address);
        const ed25519Factory = await ethers.getContractFactory('Ed25519Verify',wallet)
        ed25519Verify  =  ed25519Factory.attach(`0x2C7BA6a523d46Efb3373E9AaaBeBDE43cD321f18`) as Ed25519Verify;
        const gatewayFactory = await ethers.getContractFactory('HashCastGateway',wallet)
        gateway  =  gatewayFactory.attach(`0xc773666EEE5A80093b9584DC8F005d3D55AB5CA3`) as HashCastGateway;
        gateway = gateway.connect(wallet);
    })

    it(`can verify on-chain`, async ()=>{
       
        const unsignedTx = await ed25519Verify.populateTransaction.verify(`0x06cf14cfae0ff9fe7fdf773202029a3e8976465c8919f4840d1c3c77c8162435`,
        `0xa6161c95fd4e3237b7dd12cc3052aaa69382510ecb5b89c2fbeb8b6efb78266b`, 
        `0x81160af2842235a0257fc1d3e968c2c1c9f56f117da3186effcaeda256c38a0d`, 
        `0xb0d8bdfd9f4d1023dae836b2e41da5019d20c60965dc40943e2c10f2ad4ee49ab0d8bdfd9f4d1023dae836b2e41da5019d20c60965dc`)
        let r = await wallet.estimateGas({...unsignedTx,from:wallet.address});
        console.log("gasLimit:",r.toBigInt());
        await wallet.sendTransaction({...unsignedTx,gasLimit:r.toBigInt(),from:wallet.address});
        
    })

    it(`can mint on-chain`, async ()=>{
        const sk = ed25519.utils.randomPrivateKey();
        const pk = ethers.utils.hexlify(ed25519.getPublicKey(sk));
        console.log("pk:",pk);
        domain.verifyingContract = gateway.address;
        domain.chainId=84532;
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