// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract DeploySafes is Script {
    using Strings for address;
    using stdJson for string;

    address public constant Z_ADDR = address(0);

    address public immutable SAFE_IMPLEMENTATION;
    address public immutable FALLBACK_HANDLER;
    address public immutable SAFE_PROXY_FACTORY;
    address public immutable OWNER_SAFE;

    uint256 public immutable EXPECTED_OWNER_SAFE_THRESHOLD;
    uint256 public immutable EXPECTED_OWNER_SAFE_OWNER_COUNT;
    uint256 public immutable OWNER_SAFE_THRESHOLD;

    uint256 public immutable SAFE_B_THRESHOLD;
    uint256 public immutable EXPECTED_SAFE_B_OWNER_COUNT;

    address[] public OWNER_SAFE_OWNERS;
    address[] public SAFE_B_OWNERS;

    constructor() {
        SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
        FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
        SAFE_PROXY_FACTORY = vm.envAddress("SAFE_PROXY_FACTORY");
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");

        EXPECTED_OWNER_SAFE_THRESHOLD = vm.envUint("EXPECTED_OWNER_SAFE_THRESHOLD");
        EXPECTED_OWNER_SAFE_OWNER_COUNT = vm.envUint("EXPECTED_OWNER_SAFE_OWNER_COUNT");

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/signers.json");
        string memory jsonData = vm.readFile(path);

        SAFE_B_OWNERS = abi.decode(jsonData.parseRaw(".signers"), (address[]));

        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        OWNER_SAFE_OWNERS = ownerSafe.getOwners();
        OWNER_SAFE_THRESHOLD = ownerSafe.getThreshold();

        SAFE_B_THRESHOLD = vm.envUint("SAFE_B_THRESHOLD");
        EXPECTED_SAFE_B_OWNER_COUNT = vm.envUint("EXPECTED_SAFE_B_OWNER_COUNT");
    }

    function run() public {
        require(EXPECTED_OWNER_SAFE_THRESHOLD == 3, "Expected owner safe threshold must be 3");
        require(EXPECTED_OWNER_SAFE_OWNER_COUNT == 6, "Expected owner safe owner count must be 6");

        require(SAFE_B_THRESHOLD == 7, "Expected safe B threshold must be 7");
        require(EXPECTED_SAFE_B_OWNER_COUNT == 10, "Expected safe B owner count must be 10");

        require(OWNER_SAFE_THRESHOLD == EXPECTED_OWNER_SAFE_THRESHOLD, "Owner safe threshold must be 3");
        require(OWNER_SAFE_OWNERS.length == EXPECTED_OWNER_SAFE_OWNER_COUNT, "Owner safe owners length must be 6");

        require(SAFE_B_OWNERS.length == EXPECTED_SAFE_B_OWNER_COUNT, "Safe B owners length must be 10");

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

        require(safeAThreshold == EXPECTED_OWNER_SAFE_THRESHOLD, "PostCheck 1");
        require(safeAOwners.length == EXPECTED_OWNER_SAFE_OWNER_COUNT, "PostCheck 2");

        require(safeBThreshold == SAFE_B_THRESHOLD, "PostCheck 3");
        require(safeBOwners.length == EXPECTED_SAFE_B_OWNER_COUNT, "PostCheck 4");

        for (uint256 i; i < safeAOwners.length; i++) {
            require(safeAOwners[i] == OWNER_SAFE_OWNERS[i], "PostCheck 5");
        }

        for (uint256 i; i < safeBOwners.length; i++) {
            require(safeBOwners[i] == SAFE_B_OWNERS[i], "PostCheck 6");
        }

        console.log("PostCheck passed");
    }

    function _createAndInitProxy(address[] memory owners, uint256 threshold) private returns (address) {
        bytes memory initializer =
            abi.encodeCall(Safe.setup, (owners, threshold, Z_ADDR, "", FALLBACK_HANDLER, Z_ADDR, 0, payable(Z_ADDR)));
        return address(SafeProxyFactory(SAFE_PROXY_FACTORY).createProxyWithNonce(SAFE_IMPLEMENTATION, initializer, 0));
    }

    function _printOwners(address[] memory owners) private pure {
        for (uint256 i; i < owners.length; i++) {
            console.logAddress(owners[i]);
        }
    }
}
