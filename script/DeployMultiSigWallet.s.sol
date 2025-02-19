// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";
import { MockGnosisSafe } from "../test/mocks/MockGnosisSafe.sol";

/**
 * @title DeployMultiSigWallet
 * @notice Deployment script for the MultiSigWallet contract
 * 
 * This script handles both test and production deployments:
 * 
 * Test Mode (network="test"):
 * - Uses predefined test accounts (vm.addr(1), vm.addr(2), vm.addr(3))
 * - Deploys a MockGnosisSafe for admin operations
 * - Skips Etherscan verification
 * 
 * Production Mode (network="mainnet" or "goerli"):
 * - Uses owner addresses from environment variables (OWNER1, OWNER2, OWNER3)
 * - Requires GNOSIS_SAFE environment variable for admin multisig
 * - Performs Etherscan verification if ETHERSCAN_API_KEY is set
 * 
 * Required Environment Variables (Production):
 * - OWNER1: Address of first owner
 * - OWNER2: Address of second owner
 * - OWNER3: Address of third owner
 * - GNOSIS_SAFE: Address of Gnosis Safe for admin operations
 * - ETHERSCAN_API_KEY: (Optional) For contract verification
 */
contract DeployMultiSigWallet is Script, DeploymentUtils {
    function run() public returns (address) {
        // Step 1: Load owner addresses
        // In test mode: Use deterministic test addresses
        // In prod mode: Load from environment variables
        address owner1 = isTestMode ? vm.addr(1) : vm.envAddress("OWNER1");
        address owner2 = isTestMode ? vm.addr(2) : vm.envAddress("OWNER2");
        address owner3 = isTestMode ? vm.addr(3) : vm.envAddress("OWNER3");

        // Step 2: Set up owners array
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // Step 3: Set up Gnosis Safe
        // Test mode: Deploy a mock Gnosis Safe
        // Prod mode: Use address from environment
        if (isTestMode) {
            console2.log("\n=== Test Mode Infrastructure ===");
            console2.log("Deploying MockGnosisSafe for testing...");
            vm.startBroadcast();
            gnosisSafe = address(new MockGnosisSafe());
            vm.stopBroadcast();
            console2.log("MockGnosisSafe deployed at:", gnosisSafe);
        } else {
            gnosisSafe = vm.envAddress("GNOSIS_SAFE");
        }

        // Step 4: Configure deployment parameters
        DeploymentConfig memory config = DeploymentConfig({
            gnosisSafe: gnosisSafe,
            requiredConfirmations: 2, // Always require 2 confirmations for security
            owners: owners
        });

        // Step 5: Deploy the MultiSigWallet
        return deploy(config);
    }
}
