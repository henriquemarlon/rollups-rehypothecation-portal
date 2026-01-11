// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {Test} from "forge-std-1.12.0/src/Test.sol";
import {console} from "forge-std-1.12.0/src/console.sol";
import {MockApplication} from "./mocks/MockApplication.sol";
import {SafeYieldClaim} from "../src/delegatecall/SafeYieldClaim.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";
import {Outputs} from "cartesi-rollups-contracts-2.1.1/src/common/Outputs.sol";
import {IERC4626} from "@openzeppelin-contracts-5.2.0/interfaces/IERC4626.sol";
import {IInputBox} from "cartesi-rollups-contracts-2.1.1/src/inputs/IInputBox.sol";
import {ERC20ReHypothecationPortal} from "../src/portal/ERC20ReHypothecationPortal.sol";

contract ERC20ReHypothecationPortalForkTest is Test {
    // Mainnet
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC4626 constant MORPHO_VAULT = IERC4626(0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB); // Morpho Vault by https://www.steakhouse.financial/
    IInputBox constant INPUT_BOX = IInputBox(0xc70074BDD26d8cF983Ca6A5b89b8db52D5850051);

    MockApplication appContract;
    SafeYieldClaim safeYieldClaim;
    ERC20ReHypothecationPortal portal;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address yieldReceiver = makeAddr("yieldReceiver");

    function setUp() public {
        portal = new ERC20ReHypothecationPortal(INPUT_BOX, owner);
        appContract = new MockApplication();
        safeYieldClaim = new SafeYieldClaim();

        vm.prank(owner);
        portal.setERC20TokenYieldSource(address(USDC), MORPHO_VAULT);

        deal(address(USDC), user1, 10_000e6);
        deal(address(USDC), user2, 10_000e6);

        vm.prank(user1);
        USDC.approve(address(portal), type(uint256).max);
        vm.prank(user2);
        USDC.approve(address(portal), type(uint256).max);
    }

    function testFork_ClaimThenWithdraw() public {
        uint256 depositAmount1 = 1000e6;
        uint256 depositAmount2 = 2000e6;

        vm.prank(user1);
        portal.depositERC20Tokens(USDC, address(appContract), depositAmount1, "");

        vm.prank(user2);
        portal.depositERC20Tokens(USDC, address(appContract), depositAmount2, "");

        vm.warp(block.timestamp + 7 days);

        uint256 totalSupplyOffChain = depositAmount1 + depositAmount2;
        bytes memory claimCall =
            abi.encodeCall(SafeYieldClaim.safeClaim, (MORPHO_VAULT, yieldReceiver, totalSupplyOffChain));
        bytes memory delegatecallVoucher =
            abi.encodeCall(Outputs.DelegateCallVoucher, (address(safeYieldClaim), claimCall));
        appContract.executeOutput(delegatecallVoucher);

        uint256 yieldClaimed = USDC.balanceOf(yieldReceiver);

        bytes memory withdrawCall1 = abi.encodeCall(IERC4626.withdraw, (depositAmount1, user1, address(appContract)));
        bytes memory voucher1 = abi.encodeCall(Outputs.Voucher, (address(MORPHO_VAULT), 0, withdrawCall1));
        appContract.executeOutput(voucher1);

        bytes memory withdrawCall2 = abi.encodeCall(IERC4626.withdraw, (depositAmount2, user2, address(appContract)));
        bytes memory voucher2 = abi.encodeCall(Outputs.Voucher, (address(MORPHO_VAULT), 0, withdrawCall2));
        appContract.executeOutput(voucher2);

        console.log("=== Final Balances ===");
        console.log("User1 USDC balance:", USDC.balanceOf(user1));
        console.log("User2 USDC balance:", USDC.balanceOf(user2));
        console.log("Yield Receiver USDC balance:", USDC.balanceOf(yieldReceiver));
        console.log(
            "Application asset balance:", MORPHO_VAULT.previewRedeem(MORPHO_VAULT.balanceOf(address(appContract)))
        );

        assertEq(
            MORPHO_VAULT.previewRedeem(MORPHO_VAULT.balanceOf(address(appContract))),
            0,
            "Remaining shares should have zero value"
        );
        assertEq(USDC.balanceOf(user1), 10_000e6, "User1 should have recovered all deposited USDC");
        assertEq(USDC.balanceOf(user2), 10_000e6, "User2 should have recovered all deposited USDC");
        assertEq(USDC.balanceOf(yieldReceiver), yieldClaimed, "Yield receiver balance must be equal to yieldClaimed");
    }

    function testFork_WithdrawThenClaim() public {
        uint256 depositAmount1 = 1000e6;
        uint256 depositAmount2 = 2000e6;

        vm.prank(user1);
        portal.depositERC20Tokens(USDC, address(appContract), depositAmount1, "");

        vm.prank(user2);
        portal.depositERC20Tokens(USDC, address(appContract), depositAmount2, "");

        vm.warp(block.timestamp + 7 days);

        bytes memory withdrawCall1 = abi.encodeCall(IERC4626.withdraw, (depositAmount1, user1, address(appContract)));
        bytes memory voucher1 = abi.encodeCall(Outputs.Voucher, (address(MORPHO_VAULT), 0, withdrawCall1));
        appContract.executeOutput(voucher1);

        bytes memory withdrawCall2 = abi.encodeCall(IERC4626.withdraw, (depositAmount2, user2, address(appContract)));
        bytes memory voucher2 = abi.encodeCall(Outputs.Voucher, (address(MORPHO_VAULT), 0, withdrawCall2));
        appContract.executeOutput(voucher2);

        uint256 totalSupplyOffChain = 0;
        bytes memory claimCall =
            abi.encodeCall(SafeYieldClaim.safeClaim, (MORPHO_VAULT, yieldReceiver, totalSupplyOffChain));
        bytes memory delegatecallVoucher =
            abi.encodeCall(Outputs.DelegateCallVoucher, (address(safeYieldClaim), claimCall));
        appContract.executeOutput(delegatecallVoucher);

        uint256 yieldClaimed = USDC.balanceOf(yieldReceiver);

        console.log("=== Final Balances ===");
        console.log("User1 USDC balance:", USDC.balanceOf(user1));
        console.log("User2 USDC balance:", USDC.balanceOf(user2));
        console.log("Yield Receiver USDC balance:", USDC.balanceOf(yieldReceiver));
        console.log(
            "Application asset balance:", MORPHO_VAULT.previewRedeem(MORPHO_VAULT.balanceOf(address(appContract)))
        );

        assertEq(
            MORPHO_VAULT.previewRedeem(MORPHO_VAULT.balanceOf(address(appContract))),
            0,
            "Remaining shares should have zero value"
        );
        assertEq(USDC.balanceOf(user1), 10_000e6, "User1 should have recovered all deposited USDC");
        assertEq(USDC.balanceOf(user2), 10_000e6, "User2 should have recovered all deposited USDC");
        assertEq(USDC.balanceOf(yieldReceiver), yieldClaimed, "Yield receiver balance must be equal to yieldClaimed");
    }
}
