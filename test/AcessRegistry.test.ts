import { ethers } from "hardhat";
import chai from "chai";

import { AccessRegistry } from '../typechain';
import { verify } from "crypto";
import { BytesLike, Wallet } from "ethers";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Connection, PublicKey, clusterApiUrl, RpcResponseAndContext, SignatureResult, Keypair, Account, PUBLIC_KEY_LENGTH} from "@solana/web3.js";
import {ed25519} from '@noble/curves/ed25519';
import dotenv from 'dotenv'; 
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { CastAddBody, Factories, FarcasterNetwork, MessageData, MessageType, ReactionType, makeCastAdd, makeMessageHash,Ed25519Signer } from '@farcaster/core';

import { encrypt, decrypt, PrivateKey, ECIES_CONFIG} from 'eciesjs'


dotenv.config()

const { expect } = chai;

const domain = {
    name: 'AccessRegistry',
    version: '1.0.0',
    chainId: 31337,
    verifyingContract: ethers.constants.AddressZero
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
    ]
  }
describe('AccessRegistry', () => {
    let ar: AccessRegistry
    let owner: SignerWithAddress
    before('deploy Ed25519', async () => {
        const ed25519Factory = await ethers.getContractFactory("Ed25519");
        const ed25519Lib = await ed25519Factory.deploy();
        const blake3Factory = await ethers.getContractFactory("Blake3");
        const blake3Lib = (await blake3Factory.deploy())
        const arFactory = await ethers.getContractFactory('AccessRegistry',{
            libraries:{
                Ed25519:ed25519Lib.address,
                Blake3:blake3Lib.address
            }
        })
       
        let signers = await ethers.getSigners();
        owner = signers[0];      
        ar = (await arFactory.deploy(`0x00000000fc1237824fb747abde0ff18990e59b7e`)) as AccessRegistry

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

        const ed25519Signer = Factories.Ed25519Signer.build();
        const message_data: MessageData = {
            type: MessageType.CAST_ADD,
            fid,
            timestamp,
            network: FarcasterNetwork.MAINNET,
            castAddBody: {
              embedsDeprecated: [],
              mentions: [1],
              parentCastId: {
                fid,
                hash,
              },
              text: '@dwr.eth dau goes brrr',
              mentionsPositions: [1],
              embeds: [],
            }
          };
          const public_key = (await ed25519Signer.getSignerKey())._unsafeUnwrap();
          domain.verifyingContract = ar.address;
          const vaddress = await ar.getVirtualAddress(public_key);
          const nonce = await ar.nonces(vaddress);
          const filter = ethers.utils.getAddress(`0x0000000000000000000000000000000000000001`);
          console.log("vaddress:",vaddress);
          console.log("nonce:",nonce);
          const structHash = ethers.utils._TypedDataEncoder.hash(domain, types, {from:vaddress,filter:filter,nonce:nonce})
          console.log("structHash:",structHash.slice(2,));
          
          const signature = (await ed25519Signer.signMessageHash(ethers.utils.arrayify(structHash)))._unsafeUnwrap();
      
          const [
            r, s
          ] = [
            Buffer.from(signature.slice(0, 32)),
            Buffer.from(signature.slice(32, 64))
          ];
      
          const message = (MessageData.encode(message_data).finish());
          const addFilter = {
            pubkey:public_key,
            filter,
            r,
            s,
            message
          }          
          console.log("call function");
          const gasLimit = await ar.estimateGas.addFilter(addFilter);       
          console.log("gasLimit:",gasLimit);
          const tx = await ar.addFilter(addFilter);       
          console.log(tx); 
    })

    it(`it can encrypt using signer pubkey and ECIES`,async ()=>{
        //this is an example of assymetric encryption that can be performed by a caster to every receiver in the subreddit
        //The numerous problems related to this mechanism:
        //1. each posts causes fanout
        //2. user has to login before content is decrypted so any indexable properties have to be at a higher abstraction
        const sk = ed25519.utils.randomPrivateKey();
        const pk = ethers.utils.hexlify(ed25519.getPublicKey(sk));
        ECIES_CONFIG.ellipticCurve = "ed25519";       
        const encrypted = encrypt(pk, ethers.utils.toUtf8Bytes(`hello world`));
        //Note: The encrypted data would be stored in the DB per cast * subreddit participant cardinality
        

        //Each user would login to being decrypting the queue of posts, this could be stored on local storage
        const decrypted = decrypt(sk,encrypted)
        const decoded = new TextDecoder().decode(decrypted);
        expect(decoded).to.eq(`hello world`);
       
    })
  
})