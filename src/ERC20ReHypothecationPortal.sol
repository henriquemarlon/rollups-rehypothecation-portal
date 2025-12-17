// (c) Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0 (see LICENSE)

pragma solidity ^0.8.8;

import {Currency} from "v4-core/types/Currency.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";
import {Portal} from "cartesi-rollups-contracts-2.1.1/src/portals/Portal.sol";
import {IInputBox} from "cartesi-rollups-contracts-2.1.1/src/inputs/IInputBox.sol";
import {IERC20Portal} from "cartesi-rollups-contracts-2.1.1/src/portals/IERC20Portal.sol";
import {InputEncoding} from "cartesi-rollups-contracts-2.1.1/src/common/InputEncoding.sol";

/// referece: https://github.com/OpenZeppelin/uniswap-hooks/blob/master/src/general/ReHypothecationHook.sol

/// @title ERC-20 Portal
/// 
/// @notice This contract allows anyone to perform transfers of
/// ERC-20 tokens to an application contract while informing the off-chain machine.
contract ERC20ReHypothecationPortal is IERC20Portal, Portal {
    /// @notice Constructs the portal.
    /// @param inputBox The input box used by the portal
    constructor(IInputBox inputBox) Portal(inputBox) {}

    function depositERC20Tokens(
        IERC20 token,
        address appContract,
        uint256 value,
        bytes calldata execLayerData
    ) external override {
        bool success = token.transferFrom(msg.sender, appContract, value);

        if (!success) {
            revert ERC20TransferFailed();
        }

        bytes memory payload =
            InputEncoding.encodeERC20Deposit(token, msg.sender, value, execLayerData);

        getInputBox().addInput(appContract, payload);
    }

    //     /**
    //  * @dev Returns the `yieldSource` address for a given `currency`.
    //  *
    //  * Note: Must be implemented and adapted for the desired type of yield sources, such as
    //  *  ERC-4626 Vaults, or any custom DeFi protocol interface, optionally handling native currency.
    //  */
    // function getCurrencyYieldSource(Currency currency) public view virtual returns (address yieldSource);

    // /**
    //  * @dev Deposits a specified `amount` of `currency` into its corresponding yield source.
    //  *
    //  * Note: Must be implemented and adapted for the desired type of yield sources, such as
    //  *  ERC-4626 Vaults, or any custom DeFi protocol interface, optionally handling native currency.
    //  */
    // function _depositToYieldSource(Currency currency, uint256 amount) internal virtual;

    // /**
    //  * @dev Withdraws a specified `amount` of `currency` from its corresponding yield source.
    //  *
    //  * Note: Must be implemented and adapted for the desired type of yield sources, such as
    //  *  ERC-4626 Vaults, or any custom DeFi protocol interface, optionally handling native currency.
    //  */
    // function _withdrawFromYieldSource(Currency currency, uint256 amount) internal virtual;

    // /**
    //  * @dev Gets the `amount` of `currency` deposited in its corresponding yield source.
    //  *
    //  * Note: Must be implemented and adapted for the desired type of yield sources, such as
    //  *  ERC-4626 Vaults, or any custom DeFi protocol interface, optionally handling native currency.
    //  */
    // function _getAmountInYieldSource(Currency currency) internal view virtual returns (uint256 amount);
}
