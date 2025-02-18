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

        // Deploy implementation
        vm.broadcast();
        MultiSigWallet implementation = new MultiSigWallet();
        
        // No need to initialize implementation - it will be initialized through the proxy

        // Prepare initialization data for proxy
        bytes memory initData = abi.encodeWithSelector(
            MultiSigWallet.initialize.selector,
            config.owners,
            config.requiredConfirmations
        );

        // Deploy and initialize proxy with create2
        bytes memory proxyCode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked("proxy", VERSION, SALT));
        address payable proxy;
        assembly {
            proxy := create2(0, add(proxyCode, 0x20), mload(proxyCode), salt)
        }
        require(proxy != address(0), "Proxy deployment failed");

        vm.stopBroadcast();

        // Log deployment
        console2.log("Deployed MultiSigWallet");
        console2.log("Implementation:", address(implementation));
        console2.log("Proxy:", address(proxy));
        console2.log("Version:", VERSION);

        // Only write deployment file in non-test mode
        if (!isTestMode) {
            string memory deploymentPath = string.concat(
                "deployments/",
                network,
                "/MultiSigWallet.json"
            );
            
            string memory jsonString = string.concat(
                '{"implementation":"',
                vm.toString(address(implementation)),
                '"}'
            );
            
            vm.writeFile(deploymentPath, jsonString);
        }

        return proxy;
    }
}
