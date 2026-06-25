// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function minBaseFee() external view returns (uint64);
    function setMinBaseFee(uint64 _minBaseFee) external;
    function daFootprintGasScalar() external view returns (uint16);
    function setDAFootprintGasScalar(uint16 _daFootprintGasScalar) external;
}

contract SetMinBaseFeeAndDAFootprintScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint64 internal immutable MIN_BASE_FEE;
    uint64 internal immutable NEW_MIN_BASE_FEE;
    uint16 internal immutable DA_FOOTPRINT_GAS_SCALAR;
    uint16 internal immutable NEW_DA_FOOTPRINT_GAS_SCALAR;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        MIN_BASE_FEE = uint64(vm.envUint("OLD_MIN_BASE_FEE"));
        NEW_MIN_BASE_FEE = uint64(vm.envUint("NEW_MIN_BASE_FEE"));

        DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("OLD_DA_FOOTPRINT_GAS_SCALAR"));
        NEW_DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("NEW_DA_FOOTPRINT_GAS_SCALAR"));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).minBaseFee(), NEW_MIN_BASE_FEE, "Min base fee mismatch");
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar(),
            NEW_DA_FOOTPRINT_GAS_SCALAR,
            "DA Footprint Gas Scalar mismatch"
        );
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        if (
            MIN_BASE_FEE != ISystemConfig(SYSTEM_CONFIG).minBaseFee()
                || DA_FOOTPRINT_GAS_SCALAR != ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar()
        ) {
            // Override SystemConfig state to the expected "from" values so simulations succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](2);

            // Update DA Footprint Gas Scalar (slot 0x6a)
            // Storage layout (low to high bits):
            //   - eip1559Denominator (uint32): bits 0-31
            //   - eip1559Elasticity (uint32): bits 32-63
            //   - operatorFeeScalar (uint32): bits 64-95
            //   - operatorFeeConstant (uint64): bits 96-159
            //   - daFootprintGasScalar (uint16): bits 160-175
            // Load existing slot to preserve other fields, then update daFootprintGasScalar.
            bytes32 eip1559SlotKey = bytes32(uint256(0x6a));
            uint256 existingEip1559Word = uint256(vm.load(SYSTEM_CONFIG, eip1559SlotKey));
            // Mask to preserve bits 0-159 (everything except daFootprintGasScalar)
            uint256 preserveMask = (1 << 160) - 1;
            uint256 preservedFields = existingEip1559Word & preserveMask;
            uint256 composedEip1559Word = (uint256(DA_FOOTPRINT_GAS_SCALAR) << 160) | preservedFields;
            storageOverrides[0] = Simulation.StorageOverride({key: eip1559SlotKey, value: bytes32(composedEip1559Word)});

            // Update minBaseFee (slot 0x6c)
            // Storage layout (low to high bits):
            //   - superchainConfig (address): bits 0-159
            //   - minBaseFee (uint64): bits 160-223
            // Load existing slot to preserve superchainConfig, then update minBaseFee.
            bytes32 minBaseFeeSlotKey = bytes32(uint256(0x6c));
            uint256 existingMinBaseFeeWord = uint256(vm.load(SYSTEM_CONFIG, minBaseFeeSlotKey));
            uint256 updatedMinBaseFeeWord = (existingMinBaseFeeWord & ((1 << 160) - 1)) | (uint256(MIN_BASE_FEE) << 160);
            storageOverrides[1] = Simulation.StorageOverride({key: minBaseFeeSlotKey, value: bytes32(updatedMinBaseFeeWord)});

            stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
            return stateOverrides;
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setDAFootprintGasScalar, (NEW_DA_FOOTPRINT_GAS_SCALAR)),
            value: 0
        });

        calls[1] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setMinBaseFee, (NEW_MIN_BASE_FEE)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
