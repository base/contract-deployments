// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";

contract UnpausePortal is Script {
    address internal OPTIMISM_PORTAL_PROXY = vm.envAddress("OPTIMISM_PORTAL_PROXY");
    address internal GUARDIAN = vm.envAddress("GUARDIAN");

    function run() external {
        OptimismPortal optimismPortal = OptimismPortal(payable(OPTIMISM_PORTAL_PROXY));

        vm.broadcast(GUARDIAN);
        optimismPortal.unpause();

        require(optimismPortal.paused() == false, "PausePortal: failed to unpause");
    }
}
