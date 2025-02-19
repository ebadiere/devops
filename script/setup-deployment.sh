#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print with color
print_error() { echo -e "${RED}Error: $1${NC}"; }
print_success() { echo -e "${GREEN}Success: $1${NC}"; }
print_warning() { echo -e "${YELLOW}Warning: $1${NC}"; }

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is required but not installed."
        exit 1
    fi
}

# Validate Ethereum address
validate_address() {
    local addr=$1
    if [[ ! "$addr" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        print_error "Invalid Ethereum address format: $addr"
        return 1
    fi
    return 0
}

# Check environment variables
check_env_var() {
    local var_name=$1
    local required=$2
    
    if [[ -z "${!var_name}" ]]; then
        if [[ "$required" == "true" ]]; then
            print_error "$var_name is required but not set"
            return 1
        else
            print_warning "$var_name is not set"
        fi
    else
        if [[ "$var_name" == *"ADDRESS"* ]] || [[ "$var_name" =~ ^(OWNER[123]|GNOSIS_SAFE)$ ]]; then
            validate_address "${!var_name}" || return 1
        fi
        print_success "$var_name is properly configured"
    fi
    return 0
}

# Create directories
setup_directories() {
    local dirs=("deployments/mainnet" "deployments/goerli" "deployments/sepolia" "deployments/test")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
}

# Main setup process
main() {
    echo "=== MultiSigWallet Deployment Setup ==="
    echo

    # Check required tools
    echo "Checking required tools..."
    check_command "forge" || exit 1
    check_command "cast" || exit 1
    check_command "jq" || exit 1
    print_success "All required tools are installed"
    echo

    # Load environment variables
    echo "Loading environment variables..."
    if [[ -f .env ]]; then
        source .env
        print_success "Loaded .env file"
    else
        print_warning "No .env file found, using environment variables"
    fi
    echo

    # Validate network
    echo "Validating network configuration..."
    if [[ "$NETWORK" != "test" && "$NETWORK" != "mainnet" && "$NETWORK" != "goerli" && "$NETWORK" != "sepolia" ]]; then
        print_error "Invalid network. Must be one of: test, mainnet, goerli, sepolia"
        exit 1
    fi
    print_success "Network $NETWORK is valid"
    echo

    # Check required variables
    echo "Checking environment variables..."
    local has_error=0
    
    # Network specific checks
    if [[ "$NETWORK" != "test" ]]; then
        check_env_var "RPC_URL" true || has_error=1
        check_env_var "ETHERSCAN_API_KEY" true || has_error=1
        check_env_var "GNOSIS_SAFE" true || has_error=1
    fi

    # Always required
    check_env_var "OWNER1" true || has_error=1
    check_env_var "OWNER2" true || has_error=1
    check_env_var "OWNER3" true || has_error=1

    if [[ $has_error -eq 1 ]]; then
        print_error "Environment validation failed"
        exit 1
    fi
    echo

    # Setup directories
    echo "Setting up deployment directories..."
    setup_directories
    echo

    # Verify forge configuration
    echo "Checking forge configuration..."
    if forge config &> /dev/null; then
        print_success "Forge configuration is valid"
    else
        print_error "Invalid forge configuration"
        exit 1
    fi
    echo

    # Final status
    echo "=== Setup Complete ==="
    print_success "Environment is ready for deployment"
    echo
    echo "Next steps:"
    echo "1. Review deployment configuration"
    echo "2. Run deployment with:"
    if [[ "$NETWORK" == "test" ]]; then
        echo "   forge script script/DeployMultiSigWallet.s.sol --rpc-url http://localhost:8545 -vvvv"
    else
        echo "   forge script script/DeployMultiSigWallet.s.sol --rpc-url \$RPC_URL --broadcast --verify -vvvv"
    fi
}

# Run main function
main
