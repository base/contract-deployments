// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@eth-optimism-bedrock/contracts/L1/SystemConfig.sol";

contract SetEIP1559Params is Script {
    address systemConfigProxyAddress = vm.envAddress("SYSTEM_CONFIG_PROXY");
    address proxyAdminOwner = vm.envAddress("PROXY_ADMIN_OWNER");

    uint64 gasLimit = uint64(vm.envUint("GAS_LIMIT"));

    uint32 denominator = uint32(vm.envUint("DENOMINATOR"));
    uint32 elasticityMultiplier = uint32(vm.envUint("ELASTICITY_MULTIPLIER"));


    function run() public {
        vm.startBroadcast(proxyAdminOwner);

	SystemConfig(systemConfigProxyAddress).setEIP1559Params(denominator, elasticityMultiplier);
	SystemConfig(systemConfigProxyAddress).setGasLimit(gasLimit);

	vm.stopBroadcast();
    }
}
