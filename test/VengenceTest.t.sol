// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { Vengence } from "../contracts/vengence.sol";
import { Error } from "../contracts/lib/errors/Error.sol";

contract VengenceTest is Test {
    Vengence public vengence;

    address deployer;
    address addr1;
    address addr2;
    address addr3;

    function setUp() public {
        deployer = makeAddr("deployer");
        addr1 = makeAddr("addr1");
        addr2 = makeAddr("addr2");
        addr3 = makeAddr("addr3");

        vm.prank(deployer);
        vengence = new Vengence();
    }

    function testAdminIsDeployer() public view {
        assertEq(vengence.admin(), deployer);
    }

    function testInitialBalances() public view {
        assertEq(vengence.balanceOf(deployer, 0), 10_000_000_000); // GOLD
        assertEq(vengence.balanceOf(deployer, 1), 10_000_000_000); // SILVER
        assertEq(vengence.balanceOf(deployer, 2), 1); // BATMAN
    }

    function testBalanceOfBatch() public view {
        address[] memory owners = new address[](3);
        owners[0] = deployer;
        owners[1] = deployer;
        owners[2] = deployer;

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory balances = vengence.balanceOfBatch(owners, ids);

        assertEq(balances[0], 10_000_000_000);
        assertEq(balances[1], 10_000_000_000);
        assertEq(balances[2], 1);
    }

    function testSetApprovalForAll() public {
        vm.prank(deployer);
        vengence.setApprovalForAll(addr1, true);
        assertTrue(vengence.isApprovedForAll(deployer, addr1));

        vm.prank(deployer);
        vengence.setApprovalForAll(addr1, false);
        assertFalse(vengence.isApprovedForAll(deployer, addr1));
    }

    function testSafeTransferFromByOwner() public {
        uint256 amount = 100;
        vm.prank(deployer);
        vengence.safeTransferFrom(deployer, addr1, 0, amount, "");

        assertEq(vengence.balanceOf(deployer, 0), 10_000_000_000 - amount);
        assertEq(vengence.balanceOf(addr1, 0), amount);
    }

    function testSafeTransferFromByApprovedOperator() public {
        uint256 amount = 50;
        vm.prank(deployer);
        vengence.setApprovalForAll(addr1, true);

        vm.prank(addr1);
        vengence.safeTransferFrom(deployer, addr2, 1, amount, "");

        assertEq(vengence.balanceOf(deployer, 1), 10_000_000_000 - amount);
        assertEq(vengence.balanceOf(addr2, 1), amount);
    }

    function testSafeBatchTransferFromByOwner() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(deployer);
        vengence.safeBatchTransferFrom(deployer, addr1, ids, amounts, "");

        assertEq(vengence.balanceOf(deployer, 0), 10_000_000_000 - 100);
        assertEq(vengence.balanceOf(addr1, 0), 100);
        assertEq(vengence.balanceOf(deployer, 1), 10_000_000_000 - 200);
        assertEq(vengence.balanceOf(addr1, 1), 200);
    }

    function testSafeBatchTransferFromByApprovedOperator() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 20;

        vm.prank(deployer);
        vengence.setApprovalForAll(addr1, true);

        vm.prank(addr1);
        vengence.safeBatchTransferFrom(deployer, addr2, ids, amounts, "");

        assertEq(vengence.balanceOf(deployer, 0), 10_000_000_000 - 10);
        assertEq(vengence.balanceOf(addr2, 0), 10);
        assertEq(vengence.balanceOf(deployer, 1), 10_000_000_000 - 20);
        assertEq(vengence.balanceOf(addr2, 1), 20);
    }

    function testUriForBatmanNFT() public view {
        assertEq(vengence.uri(2), "ipfs://QmaZeqnzihdSPSKkrDufPoBW3QVuYvSC6a5NCi9eVK5jhr/bat.json");
    }

    function testUriForGoldSilverTokens() public view {
        assertEq(vengence.uri(0), "");
        assertEq(vengence.uri(1), "");
    }

    // Custom Error Tests


    function testRevertAccountIdsMismatch() public {
        address[] memory owners = new address[](1);
        owners[0] = deployer;

        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.expectRevert(Error.AccountIdsMismatch.selector);
        vengence.balanceOfBatch(owners, ids);
    }

    function testRevertInvalidOwnerAddress() public {
        address[] memory owners = new address[](1);
        owners[0] = address(0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        vm.expectRevert(Error.InvalidOwnerAddress.selector);
        vengence.balanceOfBatch(owners, ids);
    }

    function testRevertTransferToZeroAddressSafeTransferFrom() public {
        vm.prank(deployer);
        vm.expectRevert(Error.TransferToZeroAddress.selector);
        vengence.safeTransferFrom(deployer, address(0), 0, 1, "");
    }

    function testRevertNotApprovedOrSenderSafeTransferFrom() public {
        vm.prank(addr1);
        vm.expectRevert(Error.NotApprovedOrSender.selector);
        vengence.safeTransferFrom(deployer, addr2, 0, 1, "");
    }

    function testRevertInsufficientBalanceSafeTransferFrom() public {
        vm.prank(deployer);
        vm.expectRevert(Error.InsufficientBalance.selector);
        vengence.safeTransferFrom(deployer, addr1, 0, 10_000_000_000 + 1, "");
    }

    function testRevertIdsAmountsMismatchSafeBatchTransferFrom() public {
        address[] memory owners = new address[](1);
        owners[0] = deployer;

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        vm.prank(deployer);
        vm.expectRevert(Error.IdsAmountsMismatch.selector);
        vengence.safeBatchTransferFrom(deployer, addr1, ids, amounts, "");
    }


}
