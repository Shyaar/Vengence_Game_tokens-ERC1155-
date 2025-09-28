import { expect } from "chai";
import { network } from "hardhat";
import { ZeroAddress } from "ethers";

const { ethers } = await network.connect();

describe("Vengence", () => {
  let vengence: any;
  let owner: any, addr1: any, addr2: any, addr3: any;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    vengence = await ethers.deployContract("Vengence");
  });

  describe("Deployment", () => {
    it("should set the deployer as the Admin", async () => {
      expect(await vengence.admin()).to.equal(owner.address);
    });

    it("should mint initial tokens to the deployer", async () => {
      expect(await vengence.balanceOf(owner.address, 0)).to.equal(10_000_000_000); // GOLD
      expect(await vengence.balanceOf(owner.address, 1)).to.equal(10_000_000_000); // SILVER
      expect(await vengence.balanceOf(owner.address, 2)).to.equal(1); // BATMAN
    });
  });

  describe("BalanceOf and BalanceOfBatch", () => {
    it("should return correct balance for a single token ID", async () => {
      expect(await vengence.balanceOf(owner.address, 0)).to.equal(10_000_000_000);
    });

    it("should return correct balances for multiple owners and ids (balanceOfBatch)", async () => {
      const balances = await vengence.balanceOfBatch(
        [owner.address, owner.address, owner.address],
        [0, 1, 2]
      );
      expect(balances[0]).to.equal(10_000_000_000);
      expect(balances[1]).to.equal(10_000_000_000);
      expect(balances[2]).to.equal(1);
    });

    it("should revert with InvalidOwnerAddress if owner is address(0) in balanceOfBatch", async () => {
      await expect(
        vengence.balanceOfBatch([ZeroAddress], [0])
      ).to.be.revertedWithCustomError(vengence, "InvalidOwnerAddress");
    });

    it("should revert with AccountIdsMismatch if _owners and _ids length mismatch in balanceOfBatch", async () => {
      await expect(
        vengence.balanceOfBatch([owner.address], [0, 1])
      ).to.be.revertedWithCustomError(vengence, "AccountIdsMismatch");
    });
  });

  describe("Approval", () => {
    it("should allow setting and checking approval for all (setApprovalForAll, isApprovedForAll)", async () => {
      await vengence.connect(owner).setApprovalForAll(addr1.address, true);
      expect(await vengence.isApprovedForAll(owner.address, addr1.address)).to.be.true;

      await vengence.connect(owner).setApprovalForAll(addr1.address, false);
      expect(await vengence.isApprovedForAll(owner.address, addr1.address)).to.be.false;
    });
  });

  describe("Transfer", () => {
    describe("safeTransferFrom", () => {
      it("should allow safeTransferFrom by owner", async () => {
        const amount = 100;
        await vengence.connect(owner).safeTransferFrom(owner.address, addr1.address, 0, amount, "0x");

        expect(await vengence.balanceOf(owner.address, 0)).to.equal(10_000_000_000 - amount);
        expect(await vengence.balanceOf(addr1.address, 0)).to.equal(amount);
      });

      it("should allow safeTransferFrom by approved operator", async () => {
        const amount = 50;
        await vengence.connect(owner).setApprovalForAll(addr1.address, true);

        await vengence.connect(addr1).safeTransferFrom(owner.address, addr2.address, 1, amount, "0x");

        expect(await vengence.balanceOf(owner.address, 1)).to.equal(10_000_000_000 - amount);
        expect(await vengence.balanceOf(addr2.address, 1)).to.equal(amount);
      });

      it("should revert with TransferToZeroAddress if transferring to address(0)", async () => {
        await expect(
          vengence.connect(owner).safeTransferFrom(owner.address, ZeroAddress, 0, 1, "0x")
        ).to.be.revertedWithCustomError(vengence, "TransferToZeroAddress");
      });

      it("should revert with NotApprovedOrSender if caller is not owner or approved", async () => {
        await expect(
          vengence.connect(addr1).safeTransferFrom(owner.address, addr2.address, 0, 1, "0x")
        ).to.be.revertedWithCustomError(vengence, "NotApprovedOrSender");
      });

      it("should revert with InsufficientBalance if sender has no balance", async () => {
        await expect(
          vengence.connect(owner).safeTransferFrom(owner.address, addr1.address, 0, 10_000_000_000 + 1, "0x")
        ).to.be.revertedWithCustomError(vengence, "InsufficientBalance");
      });
    });

    describe("safeBatchTransferFrom", () => {
      it("should allow safeBatchTransferFrom by owner", async () => {
        const ids = [0, 1];
        const amounts = [100, 200];

        await vengence.connect(owner).safeBatchTransferFrom(owner.address, addr1.address, ids, amounts, "0x");

        expect(await vengence.balanceOf(owner.address, 0)).to.equal(10_000_000_000 - 100);
        expect(await vengence.balanceOf(addr1.address, 0)).to.equal(100);
        expect(await vengence.balanceOf(owner.address, 1)).to.equal(10_000_000_000 - 200);
        expect(await vengence.balanceOf(addr1.address, 1)).to.equal(200);
      });

      it("should allow safeBatchTransferFrom by approved operator", async () => {
        const ids = [0, 1];
        const amounts = [10, 20];

        await vengence.connect(owner).setApprovalForAll(addr1.address, true);

        await vengence.connect(addr1).safeBatchTransferFrom(owner.address, addr2.address, ids, amounts, "0x");

        expect(await vengence.balanceOf(owner.address, 0)).to.equal(10_000_000_000 - 10);
        expect(await vengence.balanceOf(addr2.address, 0)).to.equal(10);
        expect(await vengence.balanceOf(owner.address, 1)).to.equal(10_000_000_000 - 20);
        expect(await vengence.balanceOf(addr2.address, 1)).to.equal(20);
      });

      it("should revert with IdsAmountsMismatch if _ids and _amounts length mismatch", async () => {
        await expect(
          vengence.connect(owner).safeBatchTransferFrom(owner.address, addr1.address, [0], [1, 2], "0x")
        ).to.be.revertedWithCustomError(vengence, "IdsAmountsMismatch");
      });

      it("should revert with TransferToZeroAddress if transferring to address(0)", async () => {
        await expect(
          vengence.connect(owner).safeBatchTransferFrom(owner.address, ZeroAddress, [0], [1], "0x")
        ).to.be.revertedWithCustomError(vengence, "TransferToZeroAddress");
      });

      it("should revert with NotApprovedOrSender if caller is not owner or approved", async () => {
        await expect(
          vengence.connect(addr1).safeBatchTransferFrom(owner.address, addr2.address, [0], [1], "0x")
        ).to.be.revertedWithCustomError(vengence, "NotApprovedOrSender");
      });

      it("should revert with InsufficientBalance if sender has no balance", async () => {
        await expect(
          vengence.connect(owner).safeBatchTransferFrom(owner.address, addr1.address, [0], [10_000_000_000 + 1], "0x")
        ).to.be.revertedWithCustomError(vengence, "InsufficientBalance");
      });
    });
  });

  describe("URI", () => {
    it("should return correct URI for BATMAN NFT", async () => {
      expect(await vengence.uri(2)).to.equal("ipfs://QmaZeqnzihdSPSKkrDufPoBW3QVuYvSC6a5NCi9eVK5jhr/bat.json");
    });

    it("should return empty URI for GOLD/SILVER tokens", async () => {
      expect(await vengence.uri(0)).to.equal("");
      expect(await vengence.uri(1)).to.equal("");
    });
  });

  describe("Events", () => {
    it("should emit ApprovalForAll event on setApprovalForAll", async () => {
      await expect(vengence.connect(owner).setApprovalForAll(addr1.address, true))
        .to.emit(vengence, "ApprovalForAll")
        .withArgs(owner.address, addr1.address, true);
    });

    it("should emit TransferSingle event on safeTransferFrom", async () => {
      const amount = 100;
      await expect(vengence.connect(owner).safeTransferFrom(owner.address, addr1.address, 0, amount, "0x"))
        .to.emit(vengence, "TransferSingle")
        .withArgs(owner.address, owner.address, addr1.address, 0, amount);
    });

    it("should emit TransferBatch event on safeBatchTransferFrom", async () => {
      const ids = [0, 1];
      const amounts = [100, 200];
      await expect(vengence.connect(owner).safeBatchTransferFrom(owner.address, addr1.address, ids, amounts, "0x"))
        .to.emit(vengence, "TransferBatch")
        .withArgs(owner.address, owner.address, addr1.address, ids, amounts);
    });


  });


});
