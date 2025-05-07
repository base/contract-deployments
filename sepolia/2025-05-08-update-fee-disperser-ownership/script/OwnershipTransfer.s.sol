// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract OwnershipTransfer is Script {
    using AddressAliasHelper for address;

    address OWNER_EOA;
    address L1_SAFE;
    address TARGET;

    Proxy proxy;
    address L1_SAFE_ALIASED;

    // Precheck assertion to make sure original admin is OWNER_EOA
    function setUp() external {
        OWNER_EOA = vm.envAddress("OWNER_EOA");
        L1_SAFE = vm.envAddress("L1_SAFE");
        TARGET = vm.envAddress("TARGET");

        proxy = Proxy(payable(TARGET));
        L1_SAFE_ALIASED = L1_SAFE.applyL1ToL2Alias();

        console.log("OWNER_EOA: %s", OWNER_EOA);
        console.log("L1_SAFE: %s", L1_SAFE);
        console.log("TARGET: %s", TARGET);
        console.log("L1_SAFE_ALIASED: %s", L1_SAFE_ALIASED);

        _preChecks();
    }

    function run() public {
        vm.broadcast(OWNER_EOA);
        proxy.changeAdmin(L1_SAFE_ALIASED);

        _postChecks();
    }

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
