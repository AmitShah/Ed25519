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
      
          const signature = await signFarcasterMessage(ed25519Signer, message_data);
          const public_key = (await ed25519Signer.getSignerKey())._unsafeUnwrap();
      
          const message = (MessageData.encode(message_data).finish());
          
          const gasLimit = await ar.estimateGas.verifyCastAddMessage(
            public_key,
            signature.r,
            signature.s,
            message
          );       
          console.log("gasLimit:",gasLimit);
          const tx = await ar.verifyCastAddMessage(
            public_key,
            signature.r,
            signature.s,
            message
          );       
          console.log(tx); 
    })
  
})