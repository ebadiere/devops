# MultiSigWallet Deployment Guide

This guide outlines the deployment process for the MultiSigWallet smart contract system. The deployment uses CREATE2 for deterministic addresses across networks and includes comprehensive security checks.

## Prerequisites

- Foundry installed and updated
- Access to network RPC endpoints
- Etherscan API key for contract verification
- Owner addresses configured
- Gnosis Safe deployed (required for testnet/mainnet)

## Gnosis Safe Setup

### For Local Testing (Anvil)
- A mock Gnosis Safe is automatically deployed
- No setup required
- Used only for development and testing

### For Testnet/Mainnet Deployment
1. Visit [Safe Global](https://safe.global/)
2. Connect your wallet to the target network (e.g., Sepolia)
3. Create a new Safe:
   - Click "Create new Safe"
   - Add owner addresses (same as OWNER1, OWNER2, OWNER3)
   - Set threshold (recommended: 2)
   - Complete the setup process
4. Copy the deployed Safe address
5. Add to your environment variables as `GNOSIS_SAFE`

## Environment Setup

1. Create a `.env` file with the following variables:

```bash
# Network Configuration
NETWORK=<network>              # Options: test, sepolia, goerli, mainnet
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
GOERLI_RPC_URL=https://eth-goerli.g.alchemy.com/v2/YOUR-API-KEY
RPC_URL=<rpc_url>             # Network RPC endpoint

# Deployment Account
PRIVATE_KEY=your_deployer_private_key  # No 0x prefix needed

# Contract Configuration
OWNER1=<address>              # First owner address
OWNER2=<address>              # Second owner address
OWNER3=<address>              # Third owner address
GNOSIS_SAFE=<address>         # Required for testnet/mainnet, not needed for local test

# Verification
ETHERSCAN_API_KEY=<key>       # Required for mainnet/testnet verification
ETHERSCAN_GAS_PRICE=auto     # or specific value in gwei
ETHERSCAN_PRIORITY_FEE=auto  # or specific value in gwei
```

2. Run the setup script:
```bash
./script/setup-deployment.sh
```

## Deployment Process

The deployment script follows these steps:

1. Validates network and configuration
2. Sets up Gnosis Safe:
   - Local: Deploys MockGnosisSafe
   - Testnet/Mainnet: Uses existing Safe from GNOSIS_SAFE env var
3. Deploys implementation contract using CREATE2
4. Verifies implementation initialization is locked
5. Deploys and initializes proxy
6. Sets up roles for all owners
7. Verifies contracts on Etherscan (if applicable)
8. Saves deployment information

### Test Deployment

```bash
# Local test deployment
forge script script/DeployMultiSigWallet.s.sol --rpc-url http://localhost:8545 -vvvv
```

### Production Deployment

```bash
# Load environment variables
source .env

# Deploy with verification
forge script script/DeployMultiSigWallet.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

### Testnet Deployment

```bash
# For Sepolia (Chain ID: 11155111)
forge script script/DeployMultiSigWallet.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --chain-id 11155111 \
    --private-key $PRIVATE_KEY \
    --ffi \
    -vvvv

# For Goerli (Chain ID: 5)
forge script script/DeployMultiSigWallet.s.sol \
    --rpc-url $GOERLI_RPC_URL \
    --broadcast \
    --verify \
    --chain-id 5 \
    --private-key $PRIVATE_KEY \
    --ffi \
    -vvvv

# Using environment variables (recommended)
forge script script/DeployMultiSigWallet.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

Make sure your `.env` file contains:
```bash
# Network Configuration
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
GOERLI_RPC_URL=https://eth-goerli.g.alchemy.com/v2/YOUR-API-KEY

# Deployment Account
PRIVATE_KEY=your_deployer_private_key  # No 0x prefix needed

# Contract Configuration
OWNER1=first_owner_address
OWNER2=second_owner_address
OWNER3=third_owner_address

# Verification
ETHERSCAN_API_KEY=your_etherscan_api_key

# Optional: Set specific gas parameters for testnets
ETHERSCAN_GAS_PRICE=auto     # or specific value in gwei
ETHERSCAN_PRIORITY_FEE=auto  # or specific value in gwei
```

> ⚠️ **Security Note**: Never commit your `.env` file or share your private keys. The `.env` file is already in `.gitignore`.

## Deployment Artifacts

Deployment information is saved in:
```
deployments/<network>/MultiSigWallet.json
```

Format:
```json
{
    "implementation": "0x...",
    "proxy": "0x...",
    "salt": "0x..."
}
```

## Security Features

1. **Deterministic Addresses**: Uses CREATE2 for consistent addresses across networks
2. **Implementation Security**: Verifies implementation cannot be initialized
3. **Role Management**: Proper initialization of all required roles
4. **Multi-sig Control**: Requires multiple confirmations for operations
5. **Admin Control**: Uses production Gnosis Safe for testnet/mainnet admin operations
6. **Verification**: Automatic contract verification on block explorers

## Post-Deployment Verification

1. Verify implementation contract is initialized and locked
2. Confirm proxy is pointing to correct implementation
3. Validate all owners have correct roles:
   - DEFAULT_ADMIN_ROLE
   - OWNER_ROLE
   - UPGRADER_ROLE
   - PAUSER_ROLE
4. Test basic functionality (submit/confirm transaction)
5. Verify Gnosis Safe integration:
   - Confirm Safe can execute admin functions
   - Test Safe interaction with wallet

## Future Extensions

### TypeScript Integration
This deployment system could be extended to support TypeScript-based deployments for platforms like Axelar:

1. Environment Variables:
   - Current `.env` configuration is compatible with TypeScript
   - Same variables could be used across both systems

2. Potential Structure:
```
scripts/
  ├── foundry/        # Current Foundry deployment
  └── typescript/     # Future TypeScript deployment
      ├── deploy.ts
      ├── utils.ts
      └── config.ts
```

3. Key Considerations:
   - Maintain same security patterns (CREATE2, validation)
   - Share environment configuration
   - Keep deterministic deployments
   - Ensure consistent logging/monitoring

This extension would enable cross-chain deployments while maintaining our security standards.

## Troubleshooting

Common issues and solutions:

1. **Network Issues**:
   - Ensure RPC endpoint is responsive
   - Check network gas settings

2. **Verification Failures**:
   - Confirm ETHERSCAN_API_KEY is valid
   - Ensure compiler settings match

3. **Role Assignment Failures**:
   - Verify owner addresses are correct
   - Check initialization parameters

4. **CREATE2 Address Mismatch**:
   - Confirm salt value is correct
   - Verify bytecode matches exactly

## Support

For deployment issues:
1. Check deployment logs
2. Verify environment configuration
3. Ensure all prerequisites are met
4. Contact the development team with:
   - Full error logs
   - Network information
   - Environment configuration (excluding private keys)
