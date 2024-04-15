import chai from "chai";

import { AccessRegistry, AccessRegistry__factory, Blake3__factory, Ed25519__factory } from '../typechain-types';
import { verify } from "crypto";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Connection, PublicKey, clusterApiUrl, RpcResponseAndContext, SignatureResult, Keypair, Account, PUBLIC_KEY_LENGTH} from "@solana/web3.js";
import {ed25519} from '@noble/curves/ed25519';
import dotenv from 'dotenv'; 
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { CastAddBody, Factories, FarcasterNetwork, MessageData, MessageType, ReactionType, makeCastAdd, makeMessageHash,Ed25519Signer, NobleEd25519Signer } from '@farcaster/core';

import { encrypt, decrypt, PrivateKey, ECIES_CONFIG} from 'eciesjs'
import { ethers, Signer, Wallet } from "ethers";
import { createSmartAccountClient } from "@biconomy/account";
import {EddsaSigner} from "biconomy-schnorr-module/packages/schnorr-validation-module"
dotenv.config()

const { expect } = chai;



const domain = {
    name: 'AccessRegistry',
    version: '1.0.0',
    chainId: 31337,
    verifyingContract: ethers.ZeroAddress
  }
  
  const types = {
    AddFilter: [{
        name: 'from',
        type: 'address'
      },
      {
        name:'filter',
        type: 'address'
      },
      {
          name:'nonce',
          type: 'uint256'
      }
    ],
    //address casthash,address vaddress,uint256 nonce
    JoinCast: [{
        name: 'casthash',
        type: 'address'
      },
      {
        name:'vaddress',
        type: 'address'
      },
      {
          name:'nonce',
          type: 'uint256'
      }
    ],

  }
describe('AccessRegistry', () => {
    let ar: AccessRegistry
    let signer: Signer
    before('Deploy Access Registry', async () => {
        const eddsaSigner = new EddsaSigner();
        // const eddsaModule = bsm.EddsaValidationModule.create({
        //     moduleAddress:``,
        //     signer:eddsaSigner
        // });
        
       

        const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
        signer = await provider.getSigner();
        console.log(await signer.getAddress());
        const smartAccount = await createSmartAccountClient({
            signer: signer,
            bundlerUrl: "", // From dashboard.biconomy.io
            paymasterUrl: "", // From dashboard.biconomy.io,
            chainId:31337
          });
        
        const ed25519Lib = await new Ed25519__factory(signer).deploy()
        const blake3Lib = await new Blake3__factory(signer).deploy()
        //const ed25519Lib = await ed25519Factory.deploy();
        // const blake3Factory = await ethers.getContractFactory("Blake3");
        // const blake3Lib = (await blake3Factory.deploy())
        ar = await new AccessRegistry__factory({"contracts/libraries/Blake3.sol:Blake3": await blake3Lib.getAddress()},signer )
        .deploy( `0x00000000fc1237824fb747abde0ff18990e59b7e`,
           await ed25519Lib.getAddress(),
           await blake3Lib.getAddress());
       
        console.log("Access Registry Deployed",await ar.getAddress());
    })

     const fid = 100;
    const timestamp = 100000000;
    const hash = Buffer.from('1111111111111111111111111111111111111111', 'hex');
    interface Signature {
        r: Buffer,
        s: Buffer,
      }
      
     const signFarcasterMessage = async (
        signer: Ed25519Signer,
        message_data: MessageData
      ): Promise<Signature> => {
        const message_hash = (await makeMessageHash(message_data))._unsafeUnwrap();
        
        const signature = (await signer.signMessageHash(message_hash))._unsafeUnwrap();
      
        const [
          r, s
        ] = [
          Buffer.from(signature.slice(0, 32)),
          Buffer.from(signature.slice(32, 64))
        ];
      
        return { r, s };
      }
    it(`can add filter on chain`, async ()=>{
        expect(ar).is.not.null;

        // const ed25519Signer = Factories.Ed25519Signer.build();
        // const message_data: MessageData = {
        //     type: MessageType.CAST_ADD,
        //     fid,
        //     timestamp,
        //     network: FarcasterNetwork.MAINNET,
        //     castAddBody: {
        //       embedsDeprecated: [],
        //       mentions: [1],
        //       parentCastId: {
        //         fid,
        //         hash,
        //       },
        //       text: '@dwr.eth dau goes brrr',
        //       mentionsPositions: [1],
        //       embeds: [],
        //     }
        //   };
        //   const public_key = (await ed25519Signer.getSignerKey())._unsafeUnwrap();
        //   domain.verifyingContract = ar.address;
        //   const vaddress = await ar.getVirtualAddress(public_key);
        //   const nonce = await ar.nonces(vaddress);
        //   const filter = ethers.utils.getAddress(`0x0000000000000000000000000000000000000001`);
        //   console.log("vaddress:",vaddress);
        //   console.log("nonce:",nonce);
        //   const structHash = ethers.utils._TypedDataEncoder.hash(domain, {AddFilter:types.AddFilter}, {from:vaddress,filter:filter,nonce:nonce})
        //   console.log("structHash:",structHash.slice(2,));
          
        //   const signature = (await ed25519Signer.signMessageHash(ethers.utils.arrayify(structHash)))._unsafeUnwrap();
      
        //   const [
        //     r, s
        //   ] = [
        //     Buffer.from(signature.slice(0, 32)),
        //     Buffer.from(signature.slice(32, 64))
        //   ];
      
        //   const message = (MessageData.encode(message_data).finish());
        //   const addFilter = {
        //     pubkey:public_key,
        //     filter,
        //     r,
        //     s,
        //     message
        //   }          
        //   console.log("call function");
        //   const gasLimit = await ar.addFilter.estimateGas(addFilter);       
        //   console.log("gasLimit:",gasLimit);
        //   const tx = await ar.addFilter(addFilter);       
        //   console.log(tx); 
    })

    it(`it can encrypt using signer pubkey and ECIES`,async ()=>{
        //this is an example of assymetric encryption that can be performed by a caster to every receiver in the subreddit
        //The numerous problems related to this mechanism:
        //1. each posts causes fanout
        //2. user has to login before content is decrypted so any indexable properties have to be at a higher abstraction
        // const sk = ed25519.utils.randomPrivateKey();
        // const pk = ethers.hexlify(ed25519.getPublicKey(sk));
        // ECIES_CONFIG.ellipticCurve = "ed25519";       
        // const encrypted = encrypt(pk, ethers.toUtf8Bytes(`hello world`));
        // //Note: The encrypted data would be stored in the DB per cast * subreddit participant cardinality
        

        // //Each user would login to being decrypting the queue of posts, this could be stored on local storage
        // const decrypted = decrypt(sk,encrypted)
        // const decoded = new TextDecoder().decode(decrypted);
        // expect(decoded).to.eq(`hello world`);
       
    })

    it(`can join cast on chain`, async ()=>{
        // expect(ar).is.not.null;
        
        // //const ed25519Signer = Factories.Ed25519Signer.build();
        // const sk = ed25519.utils.randomPrivateKey();
        // const ed25519Signer = new NobleEd25519Signer(sk);
        // const message_data: MessageData = {
        //     type: MessageType.CAST_ADD,
        //     fid,
        //     timestamp,
        //     network: FarcasterNetwork.MAINNET,
        //     castAddBody: {
        //       embedsDeprecated: [],
        //       mentions: [1],
        //       parentCastId: {
        //         fid,
        //         hash,
        //       },
        //       text: '@dwr.eth dau goes brrr',
        //       mentionsPositions: [1],
        //       embeds: [],
        //     }
        //   };
        // const message_hash = (await makeMessageHash(message_data))._unsafeUnwrap();
        // const castHash = ethers.utils.hexlify(message_hash);
        // const public_key =(await ed25519Signer.getSignerKey())._unsafeUnwrap();
        // domain.verifyingContract = ar.address;
        // const vaddress = await ar.getVirtualAddress(public_key);
        // const nonce = await ar.nonces(vaddress);
        
        // console.log("vaddress:",vaddress);
        // console.log("nonce:",nonce);
        // const structHash = ethers.utils._TypedDataEncoder.hash(domain, {JoinCast:types.JoinCast}, { casthash:castHash,vaddress:vaddress,nonce:nonce})
        // console.log("structHash:",structHash.slice(2,));
        // //const signature = ethers.utils.hexlify(ed25519.sign(ethers.utils.arrayify(structHash),sk))
        // const signature = (await ed25519Signer.signMessageHash(ethers.utils.arrayify(structHash)))._unsafeUnwrap();
      
        // const [
        // r, s
        // ] = [
        // Buffer.from(signature.slice(0, 32)),
        // Buffer.from(signature.slice(32, 64))
        // ];
    
        
        // console.log("call function");
        // const gasLimit = await ar.estimateGas.joinPrivateCast(castHash,public_key,r,s);       
        // console.log("gasLimit:",gasLimit);
        // const tx = await ar.joinPrivateCast(castHash,public_key,r,s,{gasLimit});       
        // console.log("tx:",tx);       
        // const members = await ar.getPrivateCastMembers(castHash);
        // expect(members).length(1);
        // const messageBytes = (MessageData.encode(message_data).finish());
        // const encrypted = await encrypt(members[0], messageBytes);
        // const wireData = ethers.utils.hexlify(encrypted);
        // const decrypted = await decrypt(sk, ethers.utils.arrayify(wireData));
        // expect(ethers.utils.hexlify(decrypted)).to.eq(ethers.utils.hexlify(messageBytes));

    })
  
})