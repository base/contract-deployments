// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

// Deploys a nested 3-Safe ownership structure for use as proxyAdminOwner.
//
// Structure:
//   SafeA — 3-of-13 multisig (individual signers)
//   SafeB — 1-of-13 multisig (same individual signers)
//   SafeC — 2-of-2 multisig owned by SafeA and SafeB
//
// SafeC becomes the proxyAdminOwner / l1ProxyAdminOwner.
// l2ProxyAdminOwner = uint160(SafeC) + 0x1111000000000000000000000000000000001111
//
// Required env vars:
//   L1_GNOSIS_SAFE_IMPLEMENTATION         — address of Gnosis Safe singleton
//   L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER — address of compatibility fallback handler
//   SAFE_PROXY_FACTORY                    — address of SafeProxyFactory
//
// Required input file (same directory as this script):
//   addresses.json — { "owners": ["0x...", ...] }  (exactly 13 addresses)
//
// Output file written after deployment:
//   deployed-addresses.json — { "SafeA": "0x...", "SafeB": "0x...", "SafeC": "0x..." }
//
// Run:
//   forge script DeployNestedOwnership.sol --rpc-url $L1_RPC_URL --broadcast --sender $DEPLOYER

contract DeployNestedOwnership is Script {
    using Strings for address;
    using stdJson for string;

    address public immutable SAFE_IMPLEMENTATION;
    address public immutable FALLBACK_HANDLER;
    address public immutable SAFE_PROXY_FACTORY;
    address public zAddr;

    uint256 constant SAFE_A_THRESHOLD = 3;
    uint256 constant SAFE_B_THRESHOLD = 1;
    uint256 constant SAFE_C_THRESHOLD = 2;
    uint256 constant EXPECTED_OWNER_COUNT = 13;

    constructor() {
        SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
        FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
        SAFE_PROXY_FACTORY = vm.envAddress("SAFE_PROXY_FACTORY");
    }

    function run() public {
        string memory json = vm.readFile("addresses.json");
        address[] memory owners = abi.decode(json.parseRaw(".owners"), (address[]));

        require(owners.length == EXPECTED_OWNER_COUNT, "Expected 13 owners in addresses.json");

        console.log("Deploying SafeA (3-of-13) with owners:");
        _printOwners(owners);
        console.log("Deploying SafeB (1-of-13) with same owners");

        vm.startBroadcast();
        address safeA = _createAndInitProxy(owners, SAFE_A_THRESHOLD);
        address safeB = _createAndInitProxy(owners, SAFE_B_THRESHOLD);

        address[] memory safeCOwners = new address[](2);
        safeCOwners[0] = safeA;
        safeCOwners[1] = safeB;
        address safeC = _createAndInitProxy(safeCOwners, SAFE_C_THRESHOLD);
        vm.stopBroadcast();

        _postCheck(safeA, safeB, safeC, owners);

        vm.writeFile(
            "deployed-addresses.json",
            string.concat(
                "{",
                "\"SafeA\": \"", safeA.toHexString(), "\",",
                "\"SafeB\": \"", safeB.toHexString(), "\",",
                "\"SafeC\": \"", safeC.toHexString(), "\"",
                "}"
            )
        );
    }

    function _postCheck(
        address safeAAddr,
        address safeBAddr,
        address safeCAddr,
        address[] memory expectedOwners
    ) private view {
        Safe safeA = Safe(payable(safeAAddr));
        Safe safeB = Safe(payable(safeBAddr));
        Safe safeC = Safe(payable(safeCAddr));

        require(safeA.getThreshold() == SAFE_A_THRESHOLD, "PostCheck: SafeA threshold");
        require(safeB.getThreshold() == SAFE_B_THRESHOLD, "PostCheck: SafeB threshold");
        require(safeC.getThreshold() == SAFE_C_THRESHOLD, "PostCheck: SafeC threshold");

        address[] memory safeAOwners = safeA.getOwners();
        address[] memory safeBOwners = safeB.getOwners();
        address[] memory safeCOwners = safeC.getOwners();

        require(safeAOwners.length == EXPECTED_OWNER_COUNT, "PostCheck: SafeA owner count");
        require(safeBOwners.length == EXPECTED_OWNER_COUNT, "PostCheck: SafeB owner count");
        require(safeCOwners.length == 2, "PostCheck: SafeC owner count");

        for (uint256 i; i < expectedOwners.length; i++) {
            require(safeAOwners[i] == expectedOwners[i], "PostCheck: SafeA owner mismatch");
            require(safeBOwners[i] == expectedOwners[i], "PostCheck: SafeB owner mismatch");
        }

        require(safeC.isOwner(safeAAddr), "PostCheck: SafeC should have SafeA as owner");
        require(safeC.isOwner(safeBAddr), "PostCheck: SafeC should have SafeB as owner");

        console.log("PostCheck passed");
        console.log("SafeA:", safeAAddr);
        console.log("SafeB:", safeBAddr);
        console.log("SafeC:", safeCAddr);
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
