// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "lib/optimism/packages/contracts-bedrock/src/L1/SystemConfig.sol";
import "forge-std/Script.sol";

contract DeploySystemConfig is Script {
    function run() public {
        vm.startBroadcast();
        SystemConfig systemConfigImpl = new SystemConfig();
	console.log("SystemConfig implementation deployed at: ", address(systemConfigImpl));
	vm.stopBroadcast();
    }
}
