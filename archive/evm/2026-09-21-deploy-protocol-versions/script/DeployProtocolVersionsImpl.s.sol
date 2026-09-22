// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {ProtocolVersions} from "@base-contracts/src/L1/ProtocolVersions.sol";

/// @notice Deploys the ProtocolVersions implementation.
contract DeployProtocolVersionsImpl is Script {
    string internal addressesJson;

    ProtocolVersions public protocolVersionsImpl;

    constructor() {
        addressesJson = vm.envString("ADDRESSES_JSON");
    }

    function run() external {
        vm.startBroadcast();
        protocolVersionsImpl = new ProtocolVersions();
        vm.stopBroadcast();

        require(address(protocolVersionsImpl).code.length != 0, "protocol versions implementation not deployed");
        require(
            keccak256(bytes(protocolVersionsImpl.version())) == keccak256(bytes("1.0.0")),
            "protocol versions version mismatch"
        );
        require(protocolVersionsImpl.initVersion() == 1, "protocol versions init version mismatch");

        console.log("ProtocolVersions impl:", address(protocolVersionsImpl));
        vm.writeJson(vm.toString(address(protocolVersionsImpl)), addressesJson, ".protocolVersionsImpl");
    }
}
