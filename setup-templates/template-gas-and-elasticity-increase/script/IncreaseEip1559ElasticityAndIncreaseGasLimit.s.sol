// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

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
    uint16 internal immutable DA_FOOTPRINT_GAS_SCALAR;
    uint16 internal immutable NEW_DA_FOOTPRINT_GAS_SCALAR;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        GAS_LIMIT = uint64(vm.envUint("OLD_GAS_LIMIT"));
        NEW_GAS_LIMIT = uint64(vm.envUint("NEW_GAS_LIMIT"));

        ELASTICITY = uint32(vm.envUint("OLD_ELASTICITY"));
        NEW_ELASTICITY = uint32(vm.envUint("NEW_ELASTICITY"));

        DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("OLD_DA_FOOTPRINT_GAS_SCALAR"));
        NEW_DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("NEW_DA_FOOTPRINT_GAS_SCALAR"));

        DENOMINATOR = ISystemConfig(SYSTEM_CONFIG).eip1559Denominator();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), NEW_ELASTICITY, "Elasticity mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).gasLimit(), NEW_GAS_LIMIT, "Gas Limit mismatch");
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar(),
            NEW_DA_FOOTPRINT_GAS_SCALAR,
            "DA Footprint Gas Scalar mismatch"
        );
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        if (
            GAS_LIMIT != ISystemConfig(SYSTEM_CONFIG).gasLimit()
                || ELASTICITY != ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity()
                || DA_FOOTPRINT_GAS_SCALAR != ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar()
        ) {
            // Override SystemConfig state to the expected "from" values so simulations succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            // Prepare two storage overrides for SystemConfig
            Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](2);

            // Load current packed gas config (slot 0x68) and replace only the lower 64 bits with GAS_LIMIT
            bytes32 gasConfigSlotKey = bytes32(uint256(0x68));
            uint256 gasConfigWord = uint256(vm.load(SYSTEM_CONFIG, gasConfigSlotKey));
            uint256 updatedGasConfigWord = (gasConfigWord & ~uint256(0xffffffffffffffff)) | uint256(GAS_LIMIT);
            storageOverrides[0] =
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
            storageOverrides[1] = Simulation.StorageOverride({key: eip1559SlotKey, value: bytes32(composedEip1559Word)});

            stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
            return stateOverrides;
        }
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](3);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(ISystemConfig.setEIP1559Params, (DENOMINATOR, NEW_ELASTICITY)),
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
