import { ethers } from "hardhat";
import chai from "chai";

import { Ed25519Verify } from '../typechain';
import { verify } from "crypto";
import { BytesLike, Wallet } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";

const { expect } = chai;

describe('Ed25519Verify  OnChain', () => {
    let ed25519: Ed25519Verify
    let wallet: Wallet

    before('deploy Ed25519', async () => {
        wallet = new Wallet(process.env.PK as string,new JsonRpcProvider(`https://sepolia.base.org`));
        console.log('connected:',wallet.address);
        const ed25519Factory = await ethers.getContractFactory('Ed25519Verify',wallet)
        ed25519  =  ed25519Factory.attach(`0x2C7BA6a523d46Efb3373E9AaaBeBDE43cD321f18`) as Ed25519Verify;
    })
    it(`can verify on-chain`, async ()=>{
       
        const unsignedTx = await ed25519.populateTransaction.verify(`0x06cf14cfae0ff9fe7fdf773202029a3e8976465c8919f4840d1c3c77c8162435`,
        `0xa6161c95fd4e3237b7dd12cc3052aaa69382510ecb5b89c2fbeb8b6efb78266b`, 
        `0x81160af2842235a0257fc1d3e968c2c1c9f56f117da3186effcaeda256c38a0d`, 
        `0xb0d8bdfd9f4d1023dae836b2e41da5019d20c60965dc40943e2c10f2ad4ee49ab0d8bdfd9f4d1023dae836b2e41da5019d20c60965dc`)
        let r = await wallet.estimateGas(unsignedTx);
        console.log("gasLimit:",r.toBigInt());
        await wallet.sendTransaction({...unsignedTx,gasLimit:r.toBigInt()});
        
    })
  
})