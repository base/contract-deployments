// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TransferSystemConfigProxyOwner is Script {
    address internal SYSTEM_CONFIG_PROXY = vm.envAddress("SYSTEM_CONFIG_PROXY");
    address internal OLD_OWNER = vm.envAddress("OLD_SYSTEM_CONFIG_OWNER");
    address internal NEW_OWNER = vm.envAddress("NEW_SYSTEM_CONFIG_OWNER");

    function run() public {
        require(
            OwnableUpgradeable(SYSTEM_CONFIG_PROXY).owner() == OLD_OWNER, "System config owner is not the expected owner"
        );
        vm.startBroadcast(OLD_OWNER);
        OwnableUpgradeable(SYSTEM_CONFIG_PROXY).transferOwnership(NEW_OWNER);
        require(OwnableUpgradeable(SYSTEM_CONFIG_PROXY).owner() == NEW_OWNER, "System config owner did not get updated");
        vm.stopBroadcast();
    }
}
