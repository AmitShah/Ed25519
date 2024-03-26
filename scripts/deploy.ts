import { ethers } from "hardhat";



async function main() {

    const [deployer] = await ethers.getSigners();
    
    console.log(
    "Deploying contracts with the account:",
    deployer.address
    );
    const ed25519Factory = await ethers.getContractFactory("Ed25519");
    const ed25519Lib = await ed25519Factory.deploy();
    console.log("ed25519Lib:",ed25519Lib.address);
    const blake3Factory = await ethers.getContractFactory("Blake3");
    const blake3Lib = (await blake3Factory.deploy())
    console.log("blake3Lib:",blake3Lib.address);
    const arFactory = await ethers.getContractFactory('AccessRegistry',{
            libraries:{
                Ed25519:ed25519Lib.address,
                Blake3:blake3Lib.address
            }
    })
    const ar = (await arFactory.deploy(`0x00000000fc1237824fb747abde0ff18990e59b7e`));
    console.log("accessRegistry:",ar.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });