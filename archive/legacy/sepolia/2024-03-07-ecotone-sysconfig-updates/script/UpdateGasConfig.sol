// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import "forge-std/Script.sol";

contract UpdateGasConfigSepolia is Script {

    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint256 internal SCALAR = vm.envUint("SCALAR");
    address internal OWNER = vm.envAddress("OWNER_ADDRESS");

    function _postCheck() internal view {
        require(SystemConfig(L1_SYSTEM_CONFIG).scalar() == SCALAR);
        require(SystemConfig(L1_SYSTEM_CONFIG).overhead() == 0);
    }

    function run() public {
        vm.startBroadcast(OWNER);
        SystemConfig(L1_SYSTEM_CONFIG).setGasConfig(0, SCALAR); 
        _postCheck();
        vm.stopBroadcast(); 
    }
}