// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

interface IProxyAdmin {
    function upgrade(address _proxy, address _implementation) external;
}

interface IProxy {
    function implementation() external view returns (address);
}

contract UpgradeSystemConfigScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable PROXY_ADMIN;
    address internal immutable SYSTEM_CONFIG;

    address internal immutable NEW_IMPLEMENTATION;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        NEW_IMPLEMENTATION = vm.parseJsonAddress(json, ".systemConfig");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        // NOTE: Bypass `proxyCallIfNotAdmin` modifier.
        vm.prank(PROXY_ADMIN);
        require(IProxy(SYSTEM_CONFIG).implementation() == NEW_IMPLEMENTATION);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: PROXY_ADMIN,
            // NOTE: No need to call initialize as no storage would change (only changing MAX_GAS_LIMIT and version).
            data: abi.encodeCall(IProxyAdmin.upgrade, (SYSTEM_CONFIG, NEW_IMPLEMENTATION)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
