// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {
    MultisigBuilder,
    Simulator,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";
import { Vm } from "forge-std/Vm.sol";

// This script will be signed ahead of our gas limit increase but isn't expected to be
// executed. It will be available to us in the event we need to quickly rollback the gas limit.
contract RollbackGasLimit is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint64 internal ROLLBACK_GAS_LIMIT = uint64(vm.envUint("ROLLBACK_GAS_LIMIT"));

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override view {
        assert(SystemConfig(L1_SYSTEM_CONFIG).gasLimit() == ROLLBACK_GAS_LIMIT);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(SystemConfig.setGasLimit, (ROLLBACK_GAS_LIMIT))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SYSTEM_CONFIG_OWNER;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _incrementedNonce = _getNonce(safe) + 1;
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _incrementedNonce);
    }

    // We need to expect that the gas limit will have been updated previously in our simulation
    // Use this override to specifically set the gas limit to the expected update value.
    function _addGenericOverrides() internal view override returns (SimulationStateOverride memory) {
        SimulationStorageOverride[] memory _stateOverrides = new SimulationStorageOverride[](1);
        _stateOverrides[0] = SimulationStorageOverride({
            key: 0x0000000000000000000000000000000000000000000000000000000000000068, // slot of gas limit
            value: bytes32(vm.envUint("GAS_LIMIT"))
        });
        return SimulationStateOverride({contractAddress: L1_SYSTEM_CONFIG, overrides: _stateOverrides});
    }
}
