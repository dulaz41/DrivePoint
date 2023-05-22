import { ethers } from "hardhat";
import { expect } from "chai";

describe("DrivePoint", function () {
  let drivePoint;
  let paymentToken;
  let collection;
  let owner;
  let user1;
  let user2;
  const tokenId = 1;
  const lockupAmount = 100000000000;
  const BORROWING_PERIOD = 3600; // 1 hour

  before(async () => {
    [owner, user1, user2] = await ethers.getSigners();

    const PaymentToken = await ethers.getContractFactory("ERC20");
    paymentToken = await PaymentToken.deploy();

    const Collection = await ethers.getContractFactory("ERC721");
    collection = await Collection.deploy();

    const DrivePoint = await ethers.getContractFactory("DrivePoint");
    drivePoint = await DrivePoint.deploy(
      paymentToken.address,
      collection.address
    );
  });

  it("should allow the owner to mint an NFT", async function () {
    await drivePoint.mintNFT(tokenId);
    const ownerBalance = await collection.balanceOf(owner.address);
    expect(ownerBalance).to.equal(1);
  });

  it("should allow a user to borrow a car", async function () {
    const borrowTx = await drivePoint
      .connect(user1)
      .borrowing(collection.address, tokenId, {
        value: lockupAmount,
      });
    const borrowEvent = await borrowTx
      .wait()
      .then((receipt) =>
        receipt.events.find((event) => event.event === "CarBorrowed")
      );

    expect(borrowEvent.args.borrower).to.equal(user1.address);
  });

  it("should not allow a user to return a car before the borrowing period", async function () {
    await expect(
      drivePoint.connect(user1).returning(collection.address, tokenId)
    ).to.be.revertedWith("Car not returned within the borrowing period");
  });

  it("should allow a user to return a car after the borrowing period", async function () {
    await ethers.provider.send("evm_increaseTime", [BORROWING_PERIOD]); // Move time forward by borrowing period
    await ethers.provider.send("evm_mine"); // Mine a new block to update the timestamp

    const returnTx = await drivePoint
      .connect(user1)
      .returning(collection.address, tokenId);
    const returnEvent = await returnTx
      .wait()
      .then((receipt) =>
        receipt.events.find((event) => event.event === "CarReturned")
      );

    expect(returnEvent.args.borrower).to.equal(user1.address);
  });

  it("should allow the owner to allocate REP tokens", async function () {
    const repAmount = 3;
    await drivePoint.connect(owner).scoring(user1.address, repAmount);
    const user1Balance = await paymentToken.balanceOf(user1.address);
    expect(user1Balance).to.equal(repAmount);
  });
});
