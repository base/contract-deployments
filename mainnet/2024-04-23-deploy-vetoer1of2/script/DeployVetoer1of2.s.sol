// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import {Vetoer1of2} from "@base-contracts/src/Vetoer1of2.sol";

contract DeployVetoer1of2 is Script {
    function deployL1() public {
        address opSafe = vm.envAddress("L1_OP_SAFE");
        address baseSafe = vm.envAddress("L1_BASE_SAFE");
        address initiator = vm.envAddress("L1_SECURITY_COUNCIL_SAFE");
        address proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");

        _deployVetoer1of2({opSafe: opSafe, baseSafe: baseSafe, initiator: initiator, proxyAdmin: proxyAdmin});
    }

    function _deployVetoer1of2(address opSafe, address baseSafe, address initiator, address proxyAdmin) private {
        vm.startBroadcast();

        Vetoer1of2 vetoer1of2 =
            new Vetoer1of2({opSigner_: opSafe, otherSigner_: baseSafe, initiator: initiator, target: proxyAdmin});

        vm.stopBroadcast();

        console.log("Vetoer1of2 deployed at", address(vetoer1of2));
        console.log("DelayedVetoable deployed at", vetoer1of2.delayedVetoable());
    }
}
