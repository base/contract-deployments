// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {Recovery} from "@base-contracts/src/recovery/Recovery.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract DeployRecoveryImplementation is Script {
    using AddressAliasHelper for address;

    address internal ALIASED_INCIDENT_MULTISIG;

    Recovery recoveryImpl;

    function setUp() public {
        ALIASED_INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG").applyL1ToL2Alias();
    }

    function run() public {
        vm.startBroadcast();
        recoveryImpl = new Recovery(ALIASED_INCIDENT_MULTISIG);
        console.log("Recovery implementation deployed at: ", address(recoveryImpl));
        vm.stopBroadcast();

        _postCheck();
    }

    function _postCheck() internal view {
        require(recoveryImpl.OWNER() == ALIASED_INCIDENT_MULTISIG, "Incorrect OWNER");
    }
}
