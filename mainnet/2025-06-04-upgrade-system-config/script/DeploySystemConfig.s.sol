// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

contract DeploySystemConfigScript is Script {
    SystemConfig systemConfigImpl;

    function run() public {
        vm.startBroadcast();
        systemConfigImpl = new SystemConfig();
        console.log("SystemConfig implementation deployed at: ", address(systemConfigImpl));
        vm.stopBroadcast();

        string memory obj = "root";
        string memory json = vm.serializeAddress(obj, "systemConfig", address(systemConfigImpl));
        vm.writeJson(json, "addresses.json");

        _postCheck();
    }

    function _postCheck() internal view {
        require(
            keccak256(bytes(SystemConfig(systemConfigImpl).version())) == keccak256("2.5.0+max-gas-limit-500M"),
            "SystemConfig version mismatch"
        );

        require(SystemConfig(systemConfigImpl).maximumGasLimit() == 500_000_000, "Maximum gas limit mismatch");
    }
}
