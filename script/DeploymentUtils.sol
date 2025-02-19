// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeploymentUtils
 * @notice Utility contract for deploying and initializing the MultiSigWallet
 * 
 * This contract handles:
 * 1. Network validation (mainnet, goerli, or test)
 * 2. Contract deployment (implementation and proxy)
 * 3. Role initialization
 * 4. Contract verification
 * 5. Deployment file generation
 * 
 * The deployment process:
 * 1. Deploy implementation contract
 * 2. Prepare initialization data
 * 3. Deploy and initialize proxy
 * 4. Verify contracts (if on mainnet/testnet)
 * 5. Generate deployment files
 */
abstract contract DeploymentUtils is Script {
    // Deployment configuration
    struct DeploymentConfig {
        address gnosisSafe;
        uint256 requiredConfirmations;
        address[] owners;
    }
    
    // Environment variables
    string public network;
    address public gnosisSafe;
    bool public isTestMode;
    
    // Deployment constants
    string constant VERSION = "1.0.0";
    bytes32 constant SALT = bytes32(uint256(1));
    
    constructor() {
        // Load environment variables or use defaults for testing
        try vm.envString("NETWORK") returns (string memory net) {
            network = net;
            // Set test mode if network is "test"
            isTestMode = keccak256(bytes(network)) == keccak256("test");
        } catch {
            network = "mainnet"; // Default for tests
            isTestMode = true;
        }
    }
    
    function isAllowedNetwork() internal view returns (bool) {
        if (isTestMode) return true;
        bytes32 networkHash = keccak256(bytes(network));
        return networkHash == keccak256("mainnet") || 
               networkHash == keccak256("goerli") ||
               networkHash == keccak256("sepolia");
    }
    
    function deploy(DeploymentConfig memory config) internal returns (address) {
        // Log deployment start
        console2.log("\n=== Starting MultiSigWallet Deployment ===");
        console2.log("Network:", network);
        console2.log("Test Mode:", isTestMode);
        
        // Validate network first
        if (!isAllowedNetwork()) {
            revert(string.concat("Deployment not allowed on ", network));
        }

        // Log deployment configuration
        console2.log("\n=== Deployment Configuration ===");
        console2.log("Required Confirmations:", config.requiredConfirmations);
        console2.log("Number of Owners:", config.owners.length);
        console2.log("Admin Multisig:", config.gnosisSafe);
        
        console2.log("\nOwner Addresses:");
        for (uint i = 0; i < config.owners.length; i++) {
            console2.log(string.concat("  ", vm.toString(i + 1), ". ", vm.toString(config.owners[i])));
        }

        // Validate configuration
        require(config.owners.length > 0, "No owners provided");
        require(config.requiredConfirmations > 0 && config.requiredConfirmations <= config.owners.length, 
                "Invalid required confirmations");

        // Deploy contracts
        console2.log("\n=== Contract Deployment ===");
        
        // Start broadcast session for all transactions
        vm.startBroadcast();

        // 1. Deploy implementation
        console2.log("1. Deploying Implementation Contract");
        MultiSigWallet implementation = new MultiSigWallet();
        console2.log("   -> Implementation:", address(implementation));
        
        // 2. Prepare initialization data
        console2.log("\n2. Preparing Proxy Initialization");
        bytes memory initData = abi.encodeWithSelector(
            MultiSigWallet.initialize.selector,
            config.owners,
            config.requiredConfirmations
        );

        // 3. Deploy and initialize proxy
        console2.log("3. Deploying and Initializing Proxy");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console2.log("   -> Proxy:", address(proxy));

        // End broadcast session
        vm.stopBroadcast();

        // Log deployment summary
        console2.log("\n=== Deployment Summary ===");
        console2.log("Implementation Contract:", address(implementation));
        console2.log("Proxy Contract:", address(proxy));
        console2.log("Version:", VERSION);

        // Handle verification and additional logging
        if (isTestMode) {
            console2.log("\n=== Test Mode Information ===");
            console2.log("To interact with the wallet, use the proxy address:", address(proxy));
            
            console2.log("\nProxy Initialization Data:");
            console2.log("Implementation:", address(implementation));
            console2.log("Init data:", vm.toString(initData));
            
            console2.log("\nRole Constants (for verification):");
            console2.log("DEFAULT_ADMIN_ROLE: 0x0000000000000000000000000000000000000000000000000000000000000000");
            console2.log("OWNER_ROLE:", vm.toString(keccak256("OWNER_ROLE")));
            console2.log("UPGRADER_ROLE:", vm.toString(keccak256("UPGRADER_ROLE")));
            console2.log("PAUSER_ROLE:", vm.toString(keccak256("PAUSER_ROLE")));
        } else {
            console2.log("\n=== Production Deployment Steps ===");
            // Write deployment file
            string memory deploymentPath = string.concat(
                "deployments/",
                network,
                "/MultiSigWallet.json"
            );
            
            string memory jsonString = string.concat(
                '{"implementation":"',
                vm.toString(address(implementation)),
                '","proxy":"',
                vm.toString(address(proxy)),
                '"}'
            );
            
            vm.writeFile(deploymentPath, jsonString);
            console2.log("1. Deployment addresses saved to:", deploymentPath);

            // Verify on Etherscan for mainnet/testnet
            if (bytes(vm.envString("ETHERSCAN_API_KEY")).length > 0) {
                console2.log("2. Starting contract verification...");
                string[] memory verifyImplementationCmd = new string[](7);
                verifyImplementationCmd[0] = "forge";
                verifyImplementationCmd[1] = "verify-contract";
                verifyImplementationCmd[2] = vm.toString(address(implementation));
                verifyImplementationCmd[3] = "MultiSigWallet";
                verifyImplementationCmd[4] = "--chain";
                verifyImplementationCmd[5] = network;
                verifyImplementationCmd[6] = "--watch";
                vm.ffi(verifyImplementationCmd);

                // Verify proxy contract
                string[] memory verifyProxyCmd = new string[](7);
                verifyProxyCmd[0] = "forge";
                verifyProxyCmd[1] = "verify-contract";
                verifyProxyCmd[2] = vm.toString(address(proxy));
                verifyProxyCmd[3] = "ERC1967Proxy";
                verifyProxyCmd[4] = "--chain";
                verifyProxyCmd[5] = network;
                verifyProxyCmd[6] = "--watch";
                vm.ffi(verifyProxyCmd);
                console2.log("3. Contract verification complete");
            } else {
                console2.log("Skipping verification - ETHERSCAN_API_KEY not set");
            }
        }

        console2.log("\n=== Deployment Complete ===\n");
        return address(proxy);
    }
}
