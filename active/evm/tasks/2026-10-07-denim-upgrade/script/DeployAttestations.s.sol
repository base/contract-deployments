// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {EAS} from "@base-contracts/src/vendor/eas/EAS.sol";
import {SchemaRegistry} from "@base-contracts/src/vendor/eas/SchemaRegistry.sol";

contract DeployAttestations is Script {
    function run() external {
        vm.startBroadcast();
        SchemaRegistry registry = new SchemaRegistry();
        EAS eas = new EAS();
        vm.stopBroadcast();
        require(keccak256(bytes(registry.version())) == keccak256("1.3.1-beta.2"), "registry version mismatch");
        require(keccak256(bytes(eas.version())) == keccak256("1.4.1-beta.3"), "EAS version mismatch");
        string memory path = vm.envString("ADDRESSES_JSON");
        vm.writeJson(vm.toString(address(registry)), path, ".schemaRegistry");
        vm.writeJson(vm.toString(address(eas)), path, ".eas");
    }
}
