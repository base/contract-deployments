// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

interface IProxyAdmin {
    function owner() external returns (address);
    function transferOwnership(address newOwner) external;
}

contract MigrateL1ToSecurityCouncil is NestedMultisigBuilder {
    address proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
    address delayedVetoable = vm.envAddress("L1_DELAYED_VETOABLE");
    address nestedSafe = vm.envAddress("L1_NESTED_SAFE");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override {
        address newOwner = IProxyAdmin(proxyAdmin).owner();
        if (newOwner != delayedVetoable) {
            revert("New owner not correctly set");
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = IMulticall3.Call3({
            target: address(proxyAdmin),
            allowFailure: false,
            callData: abi.encodeCall(IProxyAdmin.transferOwnership, (delayedVetoable))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return nestedSafe;
    }
}
