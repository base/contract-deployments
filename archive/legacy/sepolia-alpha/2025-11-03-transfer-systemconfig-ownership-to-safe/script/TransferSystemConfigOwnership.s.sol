// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract TransferSystemConfigOwnership is Script {
    address public immutable NEW_OWNER;
    address public immutable SYSTEM_CONFIG;

    constructor() {
        NEW_OWNER = vm.envAddress("NEW_OWNER");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
    }

    function run() public {
        Simulation.StateOverride[] memory overrides;
        bytes memory data = _buildCall();
        Simulation.logSimulationLink({to: SYSTEM_CONFIG, data: data, from: msg.sender, overrides: overrides});

        vm.startBroadcast();
        (bool success,) = SYSTEM_CONFIG.call(data);
        vm.stopBroadcast();

        require(success, "TransferSystemConfigOwnership call failed");
        _postCheck();
    }

    function _buildCall() private view returns (bytes memory) {
        return abi.encodeCall(OwnableUpgradeable.transferOwnership, (NEW_OWNER));
    }

    function _postCheck() private view {
        OwnableUpgradeable systemConfig = OwnableUpgradeable(SYSTEM_CONFIG);
        require(systemConfig.owner() == NEW_OWNER, "SystemConfig owner did not get updated");
    }
}
