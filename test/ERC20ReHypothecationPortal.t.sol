// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.8;

import {Test} from "forge-std-1.12.0/src/Test.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin-contracts-5.2.0/interfaces/IERC4626.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {ERC4626YieldSourceMock} from "./mocks/ERC4626YieldSourceMock.sol";
import {MockApplication} from "./mocks/MockApplication.sol";
import {ERC20ReHypothecationPortal} from "../src/ERC20ReHypothecationPortal.sol";
import {IInputBox} from "cartesi-rollups-contracts-2.1.1/src/inputs/IInputBox.sol";
import {Outputs} from "cartesi-rollups-contracts-2.1.1/src/common/Outputs.sol";

contract ERC20ReHypothecationPortalTest is Test {
    ERC20ReHypothecationPortal portal;
    MockApplication appContract;

    ERC20Mock token0;
    ERC20Mock token1;

    IERC4626 yieldSource0;
    IERC4626 yieldSource1;

    IInputBox inputBox;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address cartesi = makeAddr("cartesi");

    function setUp() public {
        inputBox = IInputBox(makeAddr("inputBox"));
        vm.mockCall(address(inputBox), abi.encodeWithSelector(IInputBox.addInput.selector), abi.encode(bytes32(0)));

        portal = new ERC20ReHypothecationPortal(inputBox);
        appContract = new MockApplication();

        token0 = new ERC20Mock("Token0", "TKN0", 18);
        token1 = new ERC20Mock("Token1", "TKN1", 18);

        yieldSource0 = IERC4626(address(new ERC4626YieldSourceMock(IERC20(address(token0)))));
        yieldSource1 = IERC4626(address(new ERC4626YieldSourceMock(IERC20(address(token1)))));

        portal.setTokenYieldSource(address(token0), yieldSource0);
        portal.setTokenYieldSource(address(token1), yieldSource1);

        token0.mint(user1, 1e30);
        token0.mint(user2, 1e30);
        token1.mint(user1, 1e30);
        token1.mint(user2, 1e30);

        vm.prank(user1);
        token0.approve(address(portal), type(uint256).max);
        vm.prank(user1);
        token1.approve(address(portal), type(uint256).max);
        vm.prank(user2);
        token0.approve(address(portal), type(uint256).max);
        vm.prank(user2);
        token1.approve(address(portal), type(uint256).max);
    }

    function test_setTokenYieldSource_alreadyConfigured_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC20ReHypothecationPortal.YieldSourceAlreadyConfigured.selector, address(token0))
        );
        portal.setTokenYieldSource(address(token0), yieldSource0);
    }

    function test_setTokenYieldSource_zeroAddress_reverts() public {
        vm.expectRevert(ERC20ReHypothecationPortal.UnsupportedToken.selector);
        portal.setTokenYieldSource(address(0), yieldSource0);
    }

    function test_setTokenYieldSource_invalidYieldSource_reverts() public {
        ERC20Mock newToken = new ERC20Mock("NewToken", "NEW", 18);

        vm.expectRevert(ERC20ReHypothecationPortal.InvalidYieldSource.selector);
        portal.setTokenYieldSource(address(newToken), IERC4626(address(0)));
    }

    function test_setTokenYieldSource_vaultAssetMismatch_reverts() public {
        ERC20Mock newToken = new ERC20Mock("NewToken", "NEW", 18);

        vm.expectRevert(
            abi.encodeWithSelector(ERC20ReHypothecationPortal.VaultAssetMismatch.selector, address(newToken), address(token0))
        );
        portal.setTokenYieldSource(address(newToken), yieldSource0);
    }

    function test_getTokenYieldSource() public view {
        assertEq(address(portal.getTokenYieldSource(address(token0))), address(yieldSource0));
        assertEq(address(portal.getTokenYieldSource(address(token1))), address(yieldSource1));
    }

    function test_deposit_yieldSourceNotConfigured_reverts() public {
        ERC20Mock newToken = new ERC20Mock("NewToken", "NEW", 18);
        newToken.mint(user1, 1e18);

        vm.startPrank(user1);
        newToken.approve(address(portal), type(uint256).max);

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20ReHypothecationPortal.YieldSourceNotConfigured.selector, address(newToken)
            )
        );
        portal.depositERC20Tokens(IERC20(address(newToken)), address(appContract), 1e18, "");
        vm.stopPrank();
    }

    function test_deposit_zeroAddress_reverts() public {
        vm.startPrank(user1);
        vm.expectRevert(ERC20ReHypothecationPortal.UnsupportedToken.selector);
        portal.depositERC20Tokens(IERC20(address(0)), address(appContract), 1e18, "");
        vm.stopPrank();
    }

    function test_deposit_transfersTokensAndMintsShares() public {
        uint256 amount = 1e18;

        uint256 userBalanceBefore = token0.balanceOf(user1);
        uint256 appSharesBefore = yieldSource0.balanceOf(address(appContract));

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount, "");

        uint256 userBalanceAfter = token0.balanceOf(user1);
        uint256 appSharesAfter = yieldSource0.balanceOf(address(appContract));

        assertEq(userBalanceAfter, userBalanceBefore - amount);
        assertEq(appSharesAfter, appSharesBefore + amount);
    }

    function test_deposit_multipleUsers() public {
        uint256 amount1 = 1e18;
        uint256 amount2 = 2e18;

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount1, "");

        vm.prank(user2);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount2, "");

        uint256 totalShares = yieldSource0.balanceOf(address(appContract));
        assertEq(totalShares, amount1 + amount2);
    }

    function test_deposit_multipleTokens() public {
        uint256 amount = 1e18;

        vm.startPrank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount, "");
        portal.depositERC20Tokens(IERC20(address(token1)), address(appContract), amount, "");
        vm.stopPrank();

        assertEq(yieldSource0.balanceOf(address(appContract)), amount);
        assertEq(yieldSource1.balanceOf(address(appContract)), amount);
    }

    // -- WITHDRAW VIA VOUCHER -- //

    function test_withdraw() public {
        uint256 depositAmount = 1e18;

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), depositAmount, "");

        uint256 userBalanceBefore = token0.balanceOf(user1);

        bytes memory withdrawCall = abi.encodeCall(IERC4626.withdraw, (depositAmount, user1, address(appContract)));
        bytes memory voucher = abi.encodeCall(Outputs.Voucher, (address(yieldSource0), 0, withdrawCall));

        appContract.executeOutput(voucher);

        assertEq(token0.balanceOf(user1), userBalanceBefore + depositAmount);
        assertEq(yieldSource0.balanceOf(address(appContract)), 0);
    }

    function test_withdraw_multipleUsers() public {
        uint256 amount1 = 1e18;
        uint256 amount2 = 2e18;

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount1, "");

        vm.prank(user2);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount2, "");

        uint256 user1BalanceBefore = token0.balanceOf(user1);
        uint256 user2BalanceBefore = token0.balanceOf(user2);

        bytes memory withdrawCall1 = abi.encodeCall(IERC4626.withdraw, (amount1, user1, address(appContract)));
        bytes memory voucher1 = abi.encodeCall(Outputs.Voucher, (address(yieldSource0), 0, withdrawCall1));
        appContract.executeOutput(voucher1);

        bytes memory withdrawCall2 = abi.encodeCall(IERC4626.withdraw, (amount2, user2, address(appContract)));
        bytes memory voucher2 = abi.encodeCall(Outputs.Voucher, (address(yieldSource0), 0, withdrawCall2));
        appContract.executeOutput(voucher2);

        assertEq(token0.balanceOf(user1), user1BalanceBefore + amount1);
        assertEq(token0.balanceOf(user2), user2BalanceBefore + amount2);
        assertEq(yieldSource0.balanceOf(address(appContract)), 0);
    }

    function test_withdraw_userGetsAmountCartesiGetsYield() public {
        uint256 amount = 1e18;

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount, "");

        vm.prank(user2);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), amount, "");

        // Simulate yield accrual (50% yield)
        token0.mint(address(yieldSource0), amount); // 1e18 yield on 2e18 deposited = 50%

        // User1 withdraws their deposited amount
        _executeVoucher(
            address(yieldSource0),
            abi.encodeCall(IERC4626.withdraw, (amount, user1, address(appContract)))
        );

        // User2 withdraws their deposited amount
        _executeVoucher(
            address(yieldSource0),
            abi.encodeCall(IERC4626.withdraw, (amount, user2, address(appContract)))
        );

        // Calculate remaining shares and expected yield using previewRedeem
        uint256 remainingShares = yieldSource0.balanceOf(address(appContract));
        uint256 expectedYield = yieldSource0.previewRedeem(remainingShares);

        // Cartesi redeems remaining shares (the yield)
        _executeVoucher(
            address(yieldSource0),
            abi.encodeCall(IERC4626.redeem, (remainingShares, cartesi, address(appContract)))
        );

        // Verify all shares were redeemed and Cartesi got the yield
        assertEq(yieldSource0.balanceOf(address(appContract)), 0);
        assertEq(token0.balanceOf(cartesi), expectedYield);
    }

    function _executeVoucher(address target, bytes memory payload) internal {
        appContract.executeOutput(abi.encodeCall(Outputs.Voucher, (target, 0, payload)));
    }

    function testFuzz_depositAndWithdraw(uint128 depositAmount) public {
        depositAmount = uint128(bound(depositAmount, 1e12, 1e20));

        vm.prank(user1);
        portal.depositERC20Tokens(IERC20(address(token0)), address(appContract), depositAmount, "");

        uint256 userBalanceBefore = token0.balanceOf(user1);

        bytes memory withdrawCall = abi.encodeCall(IERC4626.withdraw, (depositAmount, user1, address(appContract)));
        bytes memory voucher = abi.encodeCall(Outputs.Voucher, (address(yieldSource0), 0, withdrawCall));

        appContract.executeOutput(voucher);

        assertEq(token0.balanceOf(user1), userBalanceBefore + depositAmount);
        assertEq(yieldSource0.balanceOf(address(appContract)), 0);
    }
}
