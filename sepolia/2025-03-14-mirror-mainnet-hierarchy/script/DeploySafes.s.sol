// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {GnosisSafe} from "safe-smart-account/GnosisSafe.sol";
import {GnosisSafeProxy} from "safe-smart-account/proxies/GnosisSafeProxy.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract DeploySafes is Script {
    using Strings for address;

    address private SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
    address private FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
    address private OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address private zAddr;

    // Need to deploy a SafeA and a SafeB with the same owners as current proxy admin owner
    function run() public {
        GnosisSafe ownerSafe = GnosisSafe(payable(OWNER_SAFE));
        address[] memory owners = ownerSafe.getOwners();

        vm.startBroadcast();
        // First safe maintains the same owners + threshold as the current proxy admin owner
        address safeA = _createAndInitProxy(owners, ownerSafe.getThreshold());
        // Second safe just uses threshold of 1
        address safeB = _createAndInitProxy(owners, 1);
        vm.stopBroadcast();

        vm.writeFile(
            "addresses.json",
            string.concat(
                "{", "\"SafeA\": \"", safeA.toHexString(), "\",", "\"SafeB\": \"", safeB.toHexString(), "\"" "}"
            )
        );
    }

    function _createAndInitProxy(address[] memory owners, uint256 threshold) private returns (address) {
        GnosisSafe proxy = GnosisSafe(payable(address(new GnosisSafeProxy(SAFE_IMPLEMENTATION))));
        proxy.setup(owners, threshold, zAddr, "", FALLBACK_HANDLER, zAddr, 0, payable(zAddr));
        return address(proxy);
    }
}
