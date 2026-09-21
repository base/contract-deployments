// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

/// @notice Deploys the uninitialized proxy for ProtocolVersions.
contract DeployProtocolVersionsProxy is Script {
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address internal immutable proxyAdmin;
    string internal addressesJson;

    Proxy public protocolVersionsProxy;

    constructor() {
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        addressesJson = vm.envString("ADDRESSES_JSON");
    }

    function setUp() public view {
        require(proxyAdmin.code.length != 0, "proxy admin not deployed");
    }

    function run() external {
        vm.startBroadcast();
        protocolVersionsProxy = new Proxy(proxyAdmin);
        vm.stopBroadcast();

        require(address(protocolVersionsProxy).code.length != 0, "protocol versions proxy not deployed");
        require(_slotAddress(address(protocolVersionsProxy), ADMIN_SLOT) == proxyAdmin, "proxy admin mismatch");
        require(_slotAddress(address(protocolVersionsProxy), IMPLEMENTATION_SLOT) == address(0), "proxy initialized");

        console.log("ProtocolVersions proxy:", address(protocolVersionsProxy));
        vm.writeJson(vm.toString(address(protocolVersionsProxy)), addressesJson, ".protocolVersionsProxy");
        vm.writeJson(
            vm.toString(abi.encode(proxyAdmin)), addressesJson, ".protocolVersionsProxyConstructorArgs"
        );
    }

    function _slotAddress(address target, bytes32 slot) internal view returns (address) {
        return address(uint160(uint256(vm.load(target, slot))));
    }
}
