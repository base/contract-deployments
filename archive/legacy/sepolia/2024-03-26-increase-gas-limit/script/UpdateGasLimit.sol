// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import "forge-std/Script.sol";

contract UpdateGasLimitSepolia is Script {
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint64 internal GAS_LIMIT = uint64(vm.envUint("GAS_LIMIT"));
    address internal OWNER = vm.envAddress("OWNER_ADDRESS");

    function _postCheck() internal view {
        require(SystemConfig(L1_SYSTEM_CONFIG).gasLimit() == GAS_LIMIT);
    }

    function run() public {
        vm.startBroadcast(OWNER);
        SystemConfig(L1_SYSTEM_CONFIG).setGasLimit(GAS_LIMIT);
        _postCheck();
        vm.stopBroadcast();
    }
}
