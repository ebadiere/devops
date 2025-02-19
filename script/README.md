# MultiSigWallet Deployment Guide

This guide outlines the deployment process for the MultiSigWallet smart contract system. The deployment uses CREATE2 for deterministic addresses across networks and includes comprehensive security checks.

## Prerequisites

- Foundry installed and updated
- Access to network RPC endpoints
- Etherscan API key for contract verification
- Owner addresses configured
- Gnosis Safe deployed (for production)

## Environment Setup

1. Create a `.env` file with the following variables:

```bash
# Network Configuration
NETWORK=<network>              # Options: test, sepolia, goerli, mainnet
RPC_URL=<rpc_url>             # Network RPC endpoint

# Contract Configuration
OWNER1=<address>              # First owner address
OWNER2=<address>              # Second owner address
OWNER3=<address>              # Third owner address
GNOSIS_SAFE=<address>         # Gnosis Safe address (not required for test)

# Verification
ETHERSCAN_API_KEY=<key>       # Required for mainnet/testnet verification
```

2. Run the setup script:
```bash
./script/setup-deployment.sh
```

## Deployment Process

The deployment script follows these steps:

1. Validates network and configuration
2. Deploys implementation contract using CREATE2
3. Verifies implementation initialization is locked
4. Deploys and initializes proxy
5. Sets up roles for all owners
6. Verifies contracts on Etherscan (if applicable)
7. Saves deployment information

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
5. **Verification**: Automatic contract verification on block explorers
6. **Artifact Management**: Saves deployment information for future reference

## Post-Deployment Verification

1. Verify implementation contract is initialized and locked
2. Confirm proxy is pointing to correct implementation
3. Validate all owners have correct roles:
   - DEFAULT_ADMIN_ROLE
   - OWNER_ROLE
   - UPGRADER_ROLE
   - PAUSER_ROLE
4. Test basic functionality (submit/confirm transaction)
5. Verify contract on block explorer

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
