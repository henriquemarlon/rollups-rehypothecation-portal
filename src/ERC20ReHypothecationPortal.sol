pragma solidity ^0.8.8;

import {Ownable} from "@openzeppelin-contracts-5.2.0/access/Ownable.sol";
import {IERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/IERC20.sol";
import {Portal} from "cartesi-rollups-contracts-2.1.1/src/portals/Portal.sol";
import {IERC4626} from "@openzeppelin-contracts-5.2.0/interfaces/IERC4626.sol";
import {IInputBox} from "cartesi-rollups-contracts-2.1.1/src/inputs/IInputBox.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/utils/SafeERC20.sol";
import {IERC20Portal} from "cartesi-rollups-contracts-2.1.1/src/portals/IERC20Portal.sol";
import {InputEncoding} from "cartesi-rollups-contracts-2.1.1/src/common/InputEncoding.sol";

/// @title ERC-20 Re-Hypothecation Portal
///
/// @notice A Cartesi Portal that enables token rehypothecation into external yield sources.
///
/// Allows users to deposit assets into external yield-generating sources (i.e. ERC-4626 vaults or lending protocols) while the application holds the vault shares and manages user balances off-chain.
///
/// Reference: https://github.com/OpenZeppelin/uniswap-hooks/blob/master/src/general/ReHypothecationHook.sol
contract ERC20ReHypothecationPortal is IERC20Portal, Portal, Ownable {
    using SafeERC20 for IERC20;

    /// @dev Mapping from token address to its ERC-4626 yield source (vault)
    mapping(address token => IERC4626 vault) private _yieldSources;

    /// @dev Error thrown when no yield source is configured for a token
    error YieldSourceNotConfigured(address token);

    /// @dev Error thrown when yield source is already configured
    error YieldSourceAlreadyConfigured(address token);

    /// @dev Error thrown when vault asset doesn't match token
    error VaultAssetMismatch(address token, address vaultAsset);

    constructor(IInputBox inputBox, address initialOwner) Portal(inputBox) Ownable(initialOwner) {}

    /// @inheritdoc IERC20Portal
    /// @dev Transfers tokens from sender, deposits into the configured ERC-4626 yield source,
    /// and notifies the application.
    /// The vault shares are held by the application, while user balances are tracked off-chain.
    function depositERC20Tokens(IERC20 token, address appContract, uint256 value, bytes calldata execLayerData)
        external
        override
    {
        IERC4626 yieldSource = _yieldSources[address(token)];
        if (address(yieldSource) == address(0)) revert YieldSourceNotConfigured(address(token));

        bool success = token.transferFrom(msg.sender, address(this), value);

        if (!success) {
            revert ERC20TransferFailed();
        }

        token.forceApprove(address(yieldSource), value);
        yieldSource.deposit(value, appContract);

        bytes memory payload = InputEncoding.encodeERC20Deposit(token, msg.sender, value, execLayerData);
        getInputBox().addInput(appContract, payload);
    }

    /// @notice Returns the yield source configured for a given token
    /// @param token The token address to query
    /// @return yieldSource The ERC-4626 vault used as yield source
    function getERC20TokenYieldSource(address token) public view returns (IERC4626 yieldSource) {
        return _yieldSources[token];
    }

    /// @notice Configures an ERC-4626 vault as the yield source for a token
    /// @param token The token address to configure
    /// @param vault The ERC-4626 vault to use as yield source
    function setERC20TokenYieldSource(address token, IERC4626 vault) external onlyOwner {
        if (address(_yieldSources[token]) != address(0)) {
            revert YieldSourceAlreadyConfigured(token);
        }
        if (vault.asset() != token) {
            revert VaultAssetMismatch(token, vault.asset());
        }
        _yieldSources[token] = vault;
    }
}
