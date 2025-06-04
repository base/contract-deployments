// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

contract DeploySystemConfig is Script {
    function run() public {
        vm.startBroadcast();
        SystemConfig systemConfigImpl = new SystemConfig();
        console.log("SystemConfig implementation deployed at: ", address(systemConfigImpl));
        vm.stopBroadcast();

        string memory obj = "root";
        string memory json = vm.serializeAddress(obj, "systemConfig", address(systemConfigImpl));
        vm.writeJson(json, "addresses.json");
    }
}
