// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.8;

import {ERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin-contracts-5.2.0/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";

/// @title ERC4626YieldSourceMock
/// @notice A mock implementation of the ERC-4626 yield source for testing.
contract ERC4626YieldSourceMock is ERC4626 {
    constructor(IERC20 token) ERC4626(token) ERC20("ERC4626YieldSourceMock", "E4626YS") {}
}
