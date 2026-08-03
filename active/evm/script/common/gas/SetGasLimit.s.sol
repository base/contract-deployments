// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";

interface ISystemConfigGasLimit {
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 gasLimit) external;
}

/// @notice Updates only the SystemConfig gas limit.
contract SetGasLimit is MultisigScript {
    bytes32 internal constant GAS_LIMIT_SLOT = bytes32(uint256(0x68));

    address internal immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal immutable SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
    uint64 internal immutable OLD_GAS_LIMIT = uint64(vm.envUint("OLD_GAS_LIMIT"));
    uint64 internal immutable NEW_GAS_LIMIT = uint64(vm.envUint("NEW_GAS_LIMIT"));

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(
            ISystemConfigGasLimit(SYSTEM_CONFIG).gasLimit() == NEW_GAS_LIMIT, "SetGasLimit: gas limit was not updated"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(ISystemConfigGasLimit.setGasLimit, (NEW_GAS_LIMIT)),
            value: 0
        });
        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory) {
        Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);
        storageOverrides[0] = Simulation.StorageOverride({key: GAS_LIMIT_SLOT, value: bytes32(uint256(OLD_GAS_LIMIT))});
        stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
        return stateOverrides;
    }
}
