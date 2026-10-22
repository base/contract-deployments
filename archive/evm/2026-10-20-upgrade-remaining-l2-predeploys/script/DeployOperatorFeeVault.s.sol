// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {OperatorFeeVault} from "@base-contracts/src/L2/OperatorFeeVault.sol";

contract DeployOperatorFeeVault is Script {
    function run() external {
        vm.startBroadcast();
        OperatorFeeVault implementation = new OperatorFeeVault();
        vm.stopBroadcast();
        require(keccak256(bytes(implementation.version())) == keccak256("1.1.0"), "operator vault version mismatch");
        vm.writeJson(vm.toString(address(implementation)), vm.envString("ADDRESSES_JSON"), ".operatorFeeVault");
    }
}
