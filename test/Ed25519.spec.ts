import { ethers } from "hardhat";
import chai from "chai";

import { Ed25519Verify } from '../typechain';
import { verify } from "crypto";

const { expect } = chai;

describe('Ed25519', () => {
    let ed25519: Ed25519Verify

    before('deploy Ed25519', async () => {
        const ed25519Factory = await ethers.getContractFactory('Ed25519Verify')
        ed25519 = (await ed25519Factory.deploy()) as Ed25519Verify
    })

    for (const { description, pub, msg, sig, valid } of require('./ed25519-tests.json')) {
        it(description, async () => {
            const [r, s] = [sig.substring(0, 64), sig.substring(64)];
            console.log(`0x${pub}`, `0x${r}`, `0x${s}`, `0x${msg}`);
            expect(valid).to.eq(await ed25519.verify(`0x${pub}`, `0x${r}`, `0x${s}`, `0x${msg}`))
       });
    }
})