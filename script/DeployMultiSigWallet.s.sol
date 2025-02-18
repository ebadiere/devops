// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";

contract DeployMultiSigWallet is Script, DeploymentUtils {
    function run() external returns (address) {
        // Load configuration
        DeploymentConfig memory config = loadConfig();

        // Deploy with configuration
        return deploy(config);
    }

    function loadConfig() internal returns (DeploymentConfig memory) {
        // Get deployment private key from environment
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        // Get Gnosis Safe address from environment or use mock for testing
        if (!isTestMode) {
            gnosisSafe = vm.envAddress("GNOSIS_SAFE");
            require(gnosisSafe != address(0), "Gnosis Safe address required");
        }

        // Load owners from environment or use defaults for testing
        address[] memory owners;
        if (!isTestMode) {
            owners = new address[](3);
            owners[0] = vm.envAddress("OWNER1");
            owners[1] = vm.envAddress("OWNER2");
            owners[2] = vm.envAddress("OWNER3");
            
            // Validate owners
            for (uint i = 0; i < owners.length; i++) {
                require(owners[i] != address(0), "Invalid owner address");
            }
        } else {
            // Use test addresses
            owners = new address[](1);
            owners[0] = address(1);
        }

        return DeploymentConfig({
            gnosisSafe: gnosisSafe,
            requiredConfirmations: isTestMode ? 1 : 2,
            owners: owners
        });
    }
}
