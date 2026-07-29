// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract OwnershipTransfer is Script {
    using AddressAliasHelper for address;

    address immutable OWNER_EOA;
    address immutable L1_SAFE;
    address immutable TARGET;

    Proxy immutable proxy;
    address immutable L1_SAFE_ALIASED;

    constructor() {
        OWNER_EOA = vm.envAddress("OWNER_EOA");
        L1_SAFE = vm.envAddress("L1_SAFE");
        TARGET = vm.envAddress("TARGET");

        proxy = Proxy(payable(TARGET));
        L1_SAFE_ALIASED = L1_SAFE.applyL1ToL2Alias();

        console.log("OWNER_EOA: %s", OWNER_EOA);
        console.log("L1_SAFE: %s", L1_SAFE);
        console.log("TARGET: %s", TARGET);
        console.log("L1_SAFE_ALIASED: %s", L1_SAFE_ALIASED);
    }

    function run() public {
        _preChecks();

        Simulation.StateOverride[] memory overrides;
        bytes memory data = abi.encodeCall(Proxy.changeAdmin, (L1_SAFE_ALIASED));
        Simulation.logSimulationLink(
            TARGET,
            data,
            OWNER_EOA,
            overrides
        );

        vm.startBroadcast(OWNER_EOA);
        (bool success, ) = TARGET.call(data);
        vm.stopBroadcast();

        require(success, "changeAdmin() call failed");

        _postChecks();
    }

    // Precheck assertion to make sure original admin is OWNER_EOA
    function _preChecks() private {
        vm.prank(address(0));
        address expectedOriginalAdmin = proxy.admin();
        require(expectedOriginalAdmin == OWNER_EOA, "Original admin is not OWNER_EOA");
    }

    function _postChecks() private {
        vm.prank(address(0));
        address admin = proxy.admin();
        require(admin == L1_SAFE_ALIASED, "New admin is not L1_SAFE_ALIASED");
    }
}
