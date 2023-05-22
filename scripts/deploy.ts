// scripts/deploy.ts
import { ethers } from "hardhat";
import * as dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const PaymentToken = await ethers.getContractFactory("ERC20");
  const paymentToken = await PaymentToken.deploy();

  const Collection = await ethers.getContractFactory("ERC721");
  const collection = await Collection.deploy();

  const DrivePoint = await ethers.getContractFactory("DrivePoint");
  const drivePoint = await DrivePoint.deploy(
    paymentToken.address,
    collection.address
  );

  console.log("ERC20 contract address:", paymentToken.address);
  console.log("ERC721 contract address:", collection.address);
  console.log("DrivePoint contract address:", drivePoint.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
