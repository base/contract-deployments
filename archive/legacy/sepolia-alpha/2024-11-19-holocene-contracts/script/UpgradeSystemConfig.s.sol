// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@eth-optimism-bedrock/contracts/L1/SystemConfig.sol";

contract UpgradeSystemConfig is Script {
    address systemConfigProxy = vm.envAddress("SYSTEM_CONFIG_PROXY");
    address systemConfigImplementation = vm.envAddress("SYSTEM_CONFIG_IMPLEMENTATION");
    address proxyAdminOwner = vm.envAddress("PROXY_ADMIN_OWNER");

    function run() public {
        vm.broadcast(proxyAdminOwner);
        ProxyAdmin proxyAdmin = ProxyAdmin(payable(vm.envAddress("PROXY_ADMIN")));

	proxyAdmin.upgrade(
	    payable(systemConfigProxy),
            systemConfigImplementation
	);
    }
}
