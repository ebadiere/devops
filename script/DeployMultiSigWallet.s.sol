// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../src/MultiSigWallet.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployMultiSigWallet is Script {
    function run() external returns (address) {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Configuration
        address[] memory owners = new address[](3);
        owners[0] = vm.addr(vm.envUint("OWNER1_KEY"));
        owners[1] = vm.addr(vm.envUint("OWNER2_KEY"));
        owners[2] = vm.addr(vm.envUint("OWNER3_KEY"));
        uint256 required = 2;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        MultiSigWallet implementation = new MultiSigWallet();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(MultiSigWallet.initialize.selector, owners, required);

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        return address(proxy);
    }
}
