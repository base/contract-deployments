// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";

contract TransferL2ProxyAdminOwner is Script {
    address internal PROXY_CONTRACT = Predeploys.PROXY_ADMIN;
    address internal OLD_OWNER = vm.envAddress("OLD_PROXY_ADMIN_OWNER_L2");
    address internal NEW_OWNER = vm.envAddress("NEW_PROXY_ADMIN_OWNER_L2");

    function run() public {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_CONTRACT);
        require(proxyAdmin.owner() == OLD_OWNER, "L2 ProxyAdmin owner is not the expected owner");
        vm.startBroadcast(OLD_OWNER);
        proxyAdmin.transferOwnership(NEW_OWNER);
        require(proxyAdmin.owner() == NEW_OWNER, "L2 ProxyAdmin owner did not get updated");
        vm.stopBroadcast();
    }
}
