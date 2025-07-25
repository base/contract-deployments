// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {Recovery} from "../src/Recovery.sol";

contract DeployRecoveryImplementation is Script {
    address internal INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG");

    Recovery recoveryImpl;

    function run() public {
        vm.startBroadcast();
        recoveryImpl = new Recovery(INCIDENT_MULTISIG);
        console.log("Recovery implementation deployed at: ", address(recoveryImpl));
        vm.stopBroadcast();

        string memory obj = "root";
        string memory json = vm.serializeAddress(obj, "implementation", address(recoveryImpl));
        vm.writeJson(json, "addresses.json");

        _postCheck();
    }

    function _postCheck() internal view {
        require(recoveryImpl.OWNER() == INCIDENT_MULTISIG, "Incorrect OWNER");
    }
}
