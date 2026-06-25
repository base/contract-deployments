// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract DeploySafes is Script {
    using Strings for address;

    address public immutable SAFE_IMPLEMENTATION;
    address public immutable FALLBACK_HANDLER;
    address public immutable SAFE_PROXY_FACTORY;
    address public immutable OWNER_SAFE;
    address public zAddr;

    address[] public OWNER_SAFE_OWNERS;
    uint256 public OWNER_SAFE_THRESHOLD;

    constructor() {
        SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
        FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
        SAFE_PROXY_FACTORY = vm.envAddress("SAFE_PROXY_FACTORY");
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    }

    function run() public {
        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        OWNER_SAFE_OWNERS = ownerSafe.getOwners();
        OWNER_SAFE_THRESHOLD = ownerSafe.getThreshold();

        require(OWNER_SAFE_OWNERS.length == 14, "Owner safe owners length must be 14");

        require(OWNER_SAFE_THRESHOLD == 3, "Owner safe threshold must be 3");

        console.log("Deploying SafeA with owners:");
        _printOwners(OWNER_SAFE_OWNERS);

        console.log("Threshold of SafeA:", OWNER_SAFE_THRESHOLD);

        vm.startBroadcast();
        // First safe maintains the same owners + threshold as the current owner safe
        address safeA = _createAndInitProxy(OWNER_SAFE_OWNERS, OWNER_SAFE_THRESHOLD);
        // Second safe specifies its own owners + threshold
        // address safeB = _createAndInitProxy(SAFE_B_OWNERS, SAFE_B_THRESHOLD);
        address safeB = 0x6AF0674791925f767060Dd52f7fB20984E8639d8;
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
        require(safeBOwners.length == 14, "PostCheck 4");

        for (uint256 i; i < safeAOwners.length; i++) {
            require(safeAOwners[i] == OWNER_SAFE_OWNERS[i], "PostCheck 5");
        }

        for (uint256 i; i < safeBOwners.length; i++) {
            require(safeBOwners[i] == OWNER_SAFE_OWNERS[i], "PostCheck 6");
        }

        console.log("PostCheck passed");
    }

    function _createAndInitProxy(address[] memory owners, uint256 threshold) private returns (address) {
        bytes memory initializer =
            abi.encodeCall(Safe.setup, (owners, threshold, zAddr, "", FALLBACK_HANDLER, zAddr, 0, payable(zAddr)));
        return address(SafeProxyFactory(SAFE_PROXY_FACTORY).createProxyWithNonce(SAFE_IMPLEMENTATION, initializer, 0));
    }

    function _printOwners(address[] memory owners) private pure {
        for (uint256 i; i < owners.length; i++) {
            console.logAddress(owners[i]);
        }
    }
}
