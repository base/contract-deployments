// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Simulation} from "@base-contracts/script/universal/MultisigBuilder.sol";
import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

interface IProxyAdmin {
    function upgrade(address _proxy, address _implementation) external;
}

interface IProxy {
    function implementation() external view returns (address);
}

contract UpgradeSystemConfig is NestedMultisigBuilder {
    address internal SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS");
    address internal PROXY_ADMIN_ADDRESS = vm.envAddress("PROXY_ADMIN_ADDRESS");
    address internal SYSTEM_CONFIG_ADDRESS = vm.envAddress("SYSTEM_CONFIG_ADDRESS");
    address internal NEW_IMPLEMENTATION = vm.envAddress("NEW_IMPLEMENTATION");

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        // NOTE: Bypass `proxyCallIfNotAdmin` modifier.
        vm.prank(PROXY_ADMIN_ADDRESS);
        require(IProxy(SYSTEM_CONFIG_ADDRESS).implementation() == NEW_IMPLEMENTATION);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](3);

        calls[0] = IMulticall3.Call3({
            target: PROXY_ADMIN_ADDRESS,
            allowFailure: false,
            // NOTE: No need to call initialize as no storage would change (only changing `MAX_GAS_LIMIT` and `version`).
            callData: abi.encodeCall(IProxyAdmin.upgrade, (SYSTEM_CONFIG_ADDRESS, NEW_IMPLEMENTATION))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SAFE_ADDRESS;
    }
}
