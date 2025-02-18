#!/bin/bash
set -e

# Check if DEPLOYER_KEY is provided
if [ -z "$DEPLOYER_KEY" ]; then
    echo "Error: DEPLOYER_KEY environment variable is required"
    exit 1
fi

# Check if password is provided
if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "Error: KEYSTORE_PASSWORD environment variable is required"
    exit 1
fi

# Create keystore directory if it doesn't exist
mkdir -p $HOME/.foundry/keystores

# Import the deployer key using cast
echo "$KEYSTORE_PASSWORD" | cast wallet import deployer --private-key "$DEPLOYER_KEY"

# Verify the key was imported
if ! cast wallet list | grep -q "deployer"; then
    echo "Error: Failed to import deployer key"
    exit 1
fi

echo "Deployment keystore setup complete"
