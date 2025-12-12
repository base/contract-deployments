// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

contract DeploySafe is Script {
    using Strings for address;
    using stdJson for string;

    address public constant Z_ADDR = address(0);

    address public immutable SAFE_IMPLEMENTATION;
    address public immutable FALLBACK_HANDLER;
    address public immutable SAFE_PROXY_FACTORY;
    address public immutable CB_NESTED_SAFE;
    address public immutable OP_SIGNER_SAFE;

    constructor() {
        SAFE_IMPLEMENTATION = vm.envAddress("L1_GNOSIS_SAFE_IMPLEMENTATION");
        FALLBACK_HANDLER = vm.envAddress("L1_GNOSIS_COMPATIBILITY_FALLBACK_HANDLER");
        SAFE_PROXY_FACTORY = vm.envAddress("SAFE_PROXY_FACTORY");

        CB_NESTED_SAFE = vm.envAddress("CB_NESTED_SAFE");
        OP_SIGNER_SAFE = vm.envAddress("OP_SIGNER_SAFE");
    }

    function run() public {
        address[] memory owners = new address[](2);
        owners[0] = CB_NESTED_SAFE;
        owners[1] = OP_SIGNER_SAFE;

        console.log("Deploying Safe with owners:");
        _printOwners(owners);

        vm.startBroadcast();
        // First safe maintains the same owners + threshold as the current owner safe
        address safe = _createAndInitProxy(owners, 2);
        vm.stopBroadcast();
        _postCheck(safe);

        vm.writeFile("addresses.json", string.concat("{", "\"Safe\": \"", safe.toHexString(), "}"));
    }

    function _postCheck(address safeAddress) private view {
        Safe safe = Safe(payable(safeAddress));

        address[] memory safeOwners = safe.getOwners();
        uint256 safeThreshold = safe.getThreshold();

        require(safeThreshold == 2, "PostCheck 1");
        require(safeOwners.length == 2, "PostCheck 2");

        require(safeOwners[0] == CB_NESTED_SAFE);
        require(safeOwners[1] == OP_SIGNER_SAFE);

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
