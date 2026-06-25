// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";

/**
 * @title DeterministicProxyDeploy
 * @notice Script for setting deploying deterministic proxies.
 */
contract DeterministicProxyDeploy is Script {

    function run(address deployer, address admin, string calldata salt) external {
        console.log("Deployer: %s", deployer);
        console.log("Admin: %s", admin);
        console.log("salt: %s", salt);
        vm.startBroadcast(deployer);
        Proxy proxy = new Proxy{ salt: keccak256(abi.encode(salt))}(admin);
        vm.stopBroadcast();
        console.log("Proxy address: %s", address(proxy));
    }
}
