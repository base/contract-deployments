// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";

import {BridgeValidator} from "bridge/BridgeValidator.sol";

contract DeployBridgeValidator is Script {
    using stdJson for string;

    address public immutable BRIDGE;
    address public immutable PARTNER_VALIDATORS;

    constructor() {
        BRIDGE = vm.envAddress("BRIDGE");
        PARTNER_VALIDATORS = vm.envAddress("PARTNER_VALIDATORS");
    }

    function run() public {
        vm.startBroadcast();
        address bridgeValidator =
            address(new BridgeValidator({bridgeAddress: BRIDGE, partnerValidators: PARTNER_VALIDATORS}));
        vm.stopBroadcast();

        _serializeAddress({key: "BridgeValidator", value: bridgeValidator});
    }

    function _serializeAddress(string memory key, address value) private {
        vm.writeJson({
            json: LibString.toHexStringChecksummed(value), path: "addresses.json", valueKey: string.concat(".", key)
        });
    }
}
