// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
               networkHash == keccak256("goerli");
    }
    
    function deploy(DeploymentConfig memory config) internal returns (address) {
        // Validate network first
        if (!isAllowedNetwork()) {
            revert(string.concat("Deployment not allowed on ", network));
        }

        // Validate configuration
        require(config.owners.length > 0, "No owners provided");
        require(config.requiredConfirmations > 0 && config.requiredConfirmations <= config.owners.length, 
                "Invalid required confirmations");

        // Start broadcast session for all transactions
        vm.startBroadcast();

        // Deploy implementation
        MultiSigWallet implementation = new MultiSigWallet();
        
        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            MultiSigWallet.initialize.selector,
            config.owners,
            config.requiredConfirmations
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // End broadcast session
        vm.stopBroadcast();

        // Log deployment
        console2.log("Deployed MultiSigWallet");
        console2.log("Implementation:", address(implementation));
        console2.log("Proxy:", address(proxy));
        console2.log("Version:", VERSION);

        // Handle verification
        if (isTestMode) {
            // For local deployment, just show the addresses
            console2.log("\nDeployment Addresses:");
            console2.log("Implementation:", address(implementation));
            console2.log("Proxy:", address(proxy));
            console2.log("\nTo interact with the wallet, use the proxy address:", address(proxy));
            
            // Show init data for reference
            console2.log("\nProxy initialization data (for reference):");
            console2.log("Implementation:", address(implementation));
            console2.log("Init data:", vm.toString(initData));
        } else {
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

            // Verify on Etherscan for mainnet/testnet
            if (bytes(vm.envString("ETHERSCAN_API_KEY")).length > 0) {
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
            } else {
                console2.log("Skipping verification - ETHERSCAN_API_KEY not set");
            }
        }

        return address(proxy);
    }
}
