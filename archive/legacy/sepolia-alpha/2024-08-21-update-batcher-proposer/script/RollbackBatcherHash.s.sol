// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Vm} from "forge-std/Vm.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract RollbackBatcherHash is Script {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    address internal ROLLBACK_BATCH_SENDER = vm.envAddress("ROLLBACK_BATCH_SENDER");

    function _convertAddressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function run() public {
        console.log("Current batcherHash: ");
        console.logBytes32(SystemConfig(L1_SYSTEM_CONFIG).batcherHash());
        // vm.prank(SYSTEM_CONFIG_OWNER);
        SystemConfig(L1_SYSTEM_CONFIG).setBatcherHash(_convertAddressToBytes32(ROLLBACK_BATCH_SENDER));
        console.log("New batcherHash: ");
        console.logBytes32(SystemConfig(L1_SYSTEM_CONFIG).batcherHash());
        require(
            SystemConfig(L1_SYSTEM_CONFIG).batcherHash() == _convertAddressToBytes32(ROLLBACK_BATCH_SENDER),
            "Rollback Deploy: batcherHash is incorrect"
        );
    }
}
