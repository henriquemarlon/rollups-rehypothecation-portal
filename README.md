<div align="center">
<img src="https://github.com/user-attachments/assets/446065f2-e029-4634-a3da-bb1a3e82fe67" width="150" height="150">
</div>
<br>
<div align="center">
<i>A Cartesi Rollups Portal for ERC-20 Token Re-Hypothecation</i>
</div>
<div align="center">
<b>Deposit tokens into yield-generating ERC-4626 vaults while maintaining Cartesi app integration</b>
</div>
<br>
<p align="center">
	<img src="https://img.shields.io/github/license/henriquemarlon/rollups-rehypothecation?style=default&logo=opensourceinitiative&logoColor=white&color=48AED9" alt="license">
	<img src="https://img.shields.io/github/last-commit/henriquemarlon/rollups-rehypothecation?style=default&logo=git&logoColor=white&color=000000" alt="last-commit">
</p>

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Environment](#environment)
  - [Running](#running)
- [Testing](#testing)
- [Development](#development)

## Overview

<!-- TODO: Add project description here -->

## Architecture

```mermaid
<!-- TODO: Add architecture diagram here -->
```

## Getting Started

### Prerequisites

1. [Install Foundry](https://book.getfoundry.sh/getting-started/installation) for smart contract development and testing;

2. Import your private key for contract deployment:

   ```sh
   cast wallet import defaultKey --interactive
   ```

   This will prompt you to enter your private key securely for contract deployment operations.

### Environment

1. Create the environment variables file:

   ```sh
   cp .env.example .env
   ```

2. Edit the `.env` file with your configuration values:

   ```
   RPC_URL=<your_rpc_url>
   ```

### Running

#### Contracts

The `ERC20ReHypothecationPortal` enables users to deposit ERC-20 tokens that are automatically routed to configured ERC-4626 yield sources (vaults). The vault shares are held by the Cartesi application while user balances are tracked off-chain.

Each deployment script saves its configuration to JSON files in the `./deployments/` directory for easy reference and integration.

During deployment, you will be prompted to enter:
- **InputBox address**: The Cartesi InputBox contract address
- **Initial owner address**: The address that will own the portal contract

1. Deploy contracts:

   ```sh
   make deploy
   ```

2. Deploy individual contracts:

   ```sh
   # Deploy ERC20ReHypothecationPortal
   make deploy-erc20-rehypothecation-portal
   ```

3. Simulate deployment (without broadcasting):

   ```sh
   make deploy-simulate
   ```

   This is useful for testing deployment scripts and verifying gas costs without actually deploying contracts.

## Testing

Run contract tests:

```sh
make test
```

## Development

### Code Quality

1. Format contracts:

   ```sh
   make fmt
   ```

### Utility Commands

1. Check contract sizes:

   ```sh
   make size
   ```

   Shows the size of all compiled contracts to ensure they fit within deployment limits.

2. Run gas reports:

   ```sh
   make gas
   ```

   Generates detailed gas usage reports for all contract functions during testing.

### Available Make Commands

For a complete list of available commands:

```sh
make help
```

This will show all available make targets with their descriptions.
