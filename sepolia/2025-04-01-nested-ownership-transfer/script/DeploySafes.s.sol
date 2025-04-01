// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract DeploySafes is Script {
    using Strings for address;

    address private SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
    address private FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
    address private OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address private zAddr;

    address[] private OWNER_SAFE_OWNERS;
    uint256 private OWNER_SAFE_THRESHOLD;

    address[] private SAFE_B_OWNERS;
    uint256 private SAFE_B_THRESHOLD;

    function run() public {
        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        OWNER_SAFE_OWNERS = ownerSafe.getOwners();
        OWNER_SAFE_THRESHOLD = ownerSafe.getThreshold();

        SAFE_B_OWNERS = abi.decode(vm.envBytes("SAFE_B_OWNERS_ENCODED"), (address[]));
        SAFE_B_THRESHOLD = vm.envUint("SAFE_B_THRESHOLD");

        require(OWNER_SAFE_OWNERS.length == 14, "Owner safe owners length must be 14");
        require(SAFE_B_OWNERS.length == 10, "Safe B owners length must be 10");

        require(OWNER_SAFE_THRESHOLD == 3, "Owner safe threshold must be 3");
        require(SAFE_B_THRESHOLD == 1, "Safe B threshold must be 1");

        console.log("Deploying SafeA with owners:");
        _printOwners(OWNER_SAFE_OWNERS);

        console.log("Deploying SafeB with owners:");
        _printOwners(SAFE_B_OWNERS);

        console.log("Threshold of SafeA:", OWNER_SAFE_THRESHOLD);
        console.log("Threshold of SafeB:", SAFE_B_THRESHOLD);

        vm.startBroadcast();
        // First safe maintains the same owners + threshold as the current owner safe
        address safeA = _createAndInitProxy(OWNER_SAFE_OWNERS, OWNER_SAFE_THRESHOLD);
        // Second safe specifies its own owners + threshold
        address safeB = _createAndInitProxy(SAFE_B_OWNERS, SAFE_B_THRESHOLD);
        vm.stopBroadcast();
        _postCheck(safeA, safeB);

        vm.writeFile(
            "addresses.json",
            string.concat(
                "{", "\"SafeA\": \"", safeA.toHexString(), "\",", "\"SafeB\": \"", safeB.toHexString(), "\"" "}"
            )
        );
    }

    function _postCheck(address safeAAddress, address safeBAddress) private view {
        Safe safeA = Safe(payable(safeAAddress));
        Safe safeB = Safe(payable(safeBAddress));

        address[] memory safeAOwners = safeA.getOwners();
        uint256 safeAThreshold = safeA.getThreshold();

        address[] memory safeBOwners = safeB.getOwners();
        uint256 safeBThreshold = safeB.getThreshold();

        require(safeAThreshold == 3, "PostCheck 1");
        require(safeBThreshold == 1, "PostCheck 2");

        require(safeAOwners.length == 14, "PostCheck 3");
        require(safeBOwners.length == 10, "PostCheck 4");

        for (uint256 i; i < safeAOwners.length; i++) {
            require(safeAOwners[i] == OWNER_SAFE_OWNERS[i], "PostCheck 5");
        }

        for (uint256 i; i < safeBOwners.length; i++) {
            require(safeBOwners[i] == SAFE_B_OWNERS[i], "PostCheck 6");
        }

        console.log("PostCheck passed");
    }

    function _createAndInitProxy(address[] memory owners, uint256 threshold) private returns (address) {
        Safe proxy = Safe(payable(address(new SafeProxy(SAFE_IMPLEMENTATION))));
        proxy.setup(owners, threshold, zAddr, "", FALLBACK_HANDLER, zAddr, 0, payable(zAddr));
        return address(proxy);
    }

    function _printOwners(address[] memory owners) private pure {
        for (uint256 i; i < owners.length; i++) {
            console.logAddress(owners[i]);
        }
    }
}
