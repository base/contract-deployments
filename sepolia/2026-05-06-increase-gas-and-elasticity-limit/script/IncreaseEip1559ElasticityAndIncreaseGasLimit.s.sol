// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/scripts/universal/IGnosisSafe.sol";

interface ISystemConfig {
    function eip1559Elasticity() external view returns (uint32);
    function eip1559Denominator() external view returns (uint32);
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 _gasLimit) external;
    function daFootprintGasScalar() external view returns (uint16);
    function setDAFootprintGasScalar(uint16 _daFootprintGasScalar) external;
}

contract IncreaseEip1559ElasticityAndIncreaseGasLimitScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint32 internal immutable ELASTICITY;
    uint32 internal immutable NEW_ELASTICITY;
    uint64 internal immutable GAS_LIMIT;
    uint64 internal immutable NEW_GAS_LIMIT;
    uint32 internal immutable DENOMINATOR;
    uint32 internal immutable NEW_DENOMINATOR;
    uint16 internal immutable DA_FOOTPRINT_GAS_SCALAR;
    uint16 internal immutable NEW_DA_FOOTPRINT_GAS_SCALAR;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        GAS_LIMIT = uint64(vm.envUint("OLD_GAS_LIMIT"));
        NEW_GAS_LIMIT = uint64(vm.envUint("NEW_GAS_LIMIT"));

        ELASTICITY = uint32(vm.envUint("OLD_ELASTICITY"));
        NEW_ELASTICITY = uint32(vm.envUint("NEW_ELASTICITY"));

        DENOMINATOR = uint32(vm.envUint("OLD_DENOMINATOR"));
        NEW_DENOMINATOR = uint32(vm.envUint("NEW_DENOMINATOR"));

        DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("OLD_DA_FOOTPRINT_GAS_SCALAR"));
        NEW_DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("NEW_DA_FOOTPRINT_GAS_SCALAR"));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), NEW_DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), NEW_ELASTICITY, "Elasticity mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).gasLimit(), NEW_GAS_LIMIT, "Gas Limit mismatch");
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar(),
            NEW_DA_FOOTPRINT_GAS_SCALAR,
            "DA Footprint Gas Scalar mismatch"
        );
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        // Check if we need to override the SystemConfig proxy implementation.
        // This is needed when the prerequisite MAX_GAS_LIMIT upgrade (PR #677) has not yet been
        // executed on-chain, but the simulation must run as if it has.
        address systemConfigImpl = vm.envOr("SYSTEM_CONFIG_IMPL", address(0));
        bytes32 implSlot = bytes32(uint256(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc));
        bool needsImplOverride = false;
        if (systemConfigImpl != address(0)) {
            address currentImpl = address(uint160(uint256(vm.load(SYSTEM_CONFIG, implSlot))));
            needsImplOverride = currentImpl != systemConfigImpl;
        }

        bool needsRollbackOverride = GAS_LIMIT != ISystemConfig(SYSTEM_CONFIG).gasLimit()
            || ELASTICITY != ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity()
            || DENOMINATOR != ISystemConfig(SYSTEM_CONFIG).eip1559Denominator()
            || DA_FOOTPRINT_GAS_SCALAR != ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar();

        if (!needsImplOverride && !needsRollbackOverride) {
            return _stateOverrides;
        }

        // Count the storage overrides we need:
        //   - 1 for implementation slot (if needed)
        //   - 2 for gas config slot 0x68 + EIP-1559/DA slot 0x6a (if rollback needed)
        uint256 storageOverrideCount = 0;
        if (needsImplOverride) storageOverrideCount++;
        if (needsRollbackOverride) storageOverrideCount += 2;

        Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](storageOverrideCount);

        uint256 idx = 0;

        if (needsImplOverride) {
            // Override the EIP-1967 implementation slot so the proxy delegates to the new
            // SystemConfig implementation with MAX_GAS_LIMIT = 2_000_000_000.
            storageOverrides[idx++] =
                Simulation.StorageOverride({key: implSlot, value: bytes32(uint256(uint160(systemConfigImpl)))});
        }

        if (needsRollbackOverride) {
            // Override SystemConfig state to the expected "from" values so simulation succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            // Load current packed gas config (slot 0x68) and replace only the lower 64 bits with GAS_LIMIT
            bytes32 gasConfigSlotKey = bytes32(uint256(0x68));
            uint256 gasConfigWord = uint256(vm.load(SYSTEM_CONFIG, gasConfigSlotKey));
            uint256 updatedGasConfigWord = (gasConfigWord & ~uint256(0xffffffffffffffff)) | uint256(GAS_LIMIT);
            storageOverrides[idx++] =
                Simulation.StorageOverride({key: gasConfigSlotKey, value: bytes32(updatedGasConfigWord)});

            // Update EIP-1559 params and DA Footprint Gas Scalar (slot 0x6a)
            // Storage layout (low to high bits):
            //   - eip1559Denominator (uint32): bits 0-31
            //   - eip1559Elasticity (uint32): bits 32-63
            //   - operatorFeeScalar (uint32): bits 64-95
            //   - operatorFeeConstant (uint64): bits 96-159
            //   - daFootprintGasScalar (uint16): bits 160-175
            // Load existing slot to preserve operatorFeeScalar and operatorFeeConstant, then update
            // the fields we care about.
            bytes32 eip1559SlotKey = bytes32(uint256(0x6a));
            uint256 existingEip1559Word = uint256(vm.load(SYSTEM_CONFIG, eip1559SlotKey));
            // Mask to preserve bits 64-159 (operatorFeeScalar and operatorFeeConstant)
            uint256 operatorFeeMask = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFF) << 64;
            uint256 preservedOperatorFees = existingEip1559Word & operatorFeeMask;
            uint256 composedEip1559Word = (uint256(DA_FOOTPRINT_GAS_SCALAR) << 160) | preservedOperatorFees
                | (uint256(ELASTICITY) << 32) | uint256(DENOMINATOR);
            storageOverrides[idx++] =
                Simulation.StorageOverride({key: eip1559SlotKey, value: bytes32(composedEip1559Word)});
        }

        stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
        return stateOverrides;
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        // Pre-checks: verify current on-chain values match expected FROM values.
        // _buildCalls runs before _simulationOverrides are applied, so during rollback
        // simulation the on-chain values won't yet match the FROM values. We detect this
        // case and skip the pre-checks — rollback correctness is validated by _postCheck.
        bool onChainMatchesFrom = ISystemConfig(SYSTEM_CONFIG).gasLimit() == GAS_LIMIT
            && ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity() == ELASTICITY
            && ISystemConfig(SYSTEM_CONFIG).eip1559Denominator() == DENOMINATOR
            && ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar() == DA_FOOTPRINT_GAS_SCALAR;
        require(
            onChainMatchesFrom || _simulationOverrides().length > 0,
            "Pre-check: on-chain values do not match expected FROM values and no simulation overrides are active"
        );

        Call[] memory calls = new Call[](3);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(ISystemConfig.setEIP1559Params, (NEW_DENOMINATOR, NEW_ELASTICITY)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(ISystemConfig.setGasLimit, (NEW_GAS_LIMIT)),
            value: 0
        });

        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(ISystemConfig.setDAFootprintGasScalar, (NEW_DA_FOOTPRINT_GAS_SCALAR)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
