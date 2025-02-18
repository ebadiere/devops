## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Secure MultiSig Wallet

A secure, upgradeable multisig wallet smart contract with comprehensive security features.

## Features

- Upgradeable contract (UUPS pattern)
- Role-based access control
- Gnosis Safe integration for admin operations
- Pausable functionality
- Reentrancy protection
- Comprehensive test coverage

## Development

```bash
# Install dependencies
forge install

# Run tests
forge test
```

## Deployment

### 1. Setup Deployment Key

For secure deployments, we use Foundry's encrypted keystore feature instead of exposing private keys in environment variables.

```bash
# Import your deployment key (you'll be prompted for the key and a password)
cast wallet import deployer --interactive

# Or use the automated setup script (requires DEPLOYER_KEY and KEYSTORE_PASSWORD env vars)
./script/setup-deployment.sh
```

### 2. Configure Deployment

Required environment variables:
- `NETWORK`: Target network (mainnet/goerli)
- `GNOSIS_SAFE`: Address of your Gnosis Safe multisig that will be the admin
- `OWNER1`, `OWNER2`, `OWNER3`: Wallet owner addresses

### 3. Deploy

```bash
# Deploy to network
forge script script/DeployMultiSigWallet.s.sol:DeployMultiSigWallet \
  --account deployer \
  --rpc-url <RPC_URL> \
  --broadcast \
  --verify
```

## Security

This contract uses several security measures:
1. All admin operations are controlled by a Gnosis Safe multisig
2. Private keys are never exposed in environment variables
3. Deployment is done through encrypted keystores
4. Role-based access control for all operations
5. Upgrades are controlled by the admin multisig

## Testing

```bash
# Run all tests
forge test

# Run with detailed logging
forge test -vvv
```

## License

MIT
