// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { DeploymentUtils } from "./DeploymentUtils.sol";
import { MockGnosisSafe } from "../test/mocks/MockGnosisSafe.sol";

contract DeployMultiSigWallet is Script, DeploymentUtils {
    function run() public returns (address) {
        // Load environment variables
        address owner1 = isTestMode ? vm.addr(1) : vm.envAddress("OWNER1");
        address owner2 = isTestMode ? vm.addr(2) : vm.envAddress("OWNER2");
        address owner3 = isTestMode ? vm.addr(3) : vm.envAddress("OWNER3");

        // Create owners array
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // Deploy mock Gnosis Safe for test mode
        if (isTestMode) {
            vm.startBroadcast();
            gnosisSafe = address(new MockGnosisSafe());
            vm.stopBroadcast();
        } else {
            gnosisSafe = vm.envAddress("GNOSIS_SAFE");
        }

        // Configure deployment
        DeploymentConfig memory config = DeploymentConfig({
            gnosisSafe: gnosisSafe,
            requiredConfirmations: 2, // Always require 2 confirmations for better security
            owners: owners
        });

        // Deploy wallet
        return deploy(config);
    }
}
