// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function eip1559Elasticity() external view returns (uint32);
    function eip1559Denominator() external view returns (uint32);
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 _gasLimit) external;
    function daFootprintGasScalar() external view returns (uint16);
    function setDAFootprintGasScalar(uint16 _daFootprintGasScalar) external;
    function minBaseFee() external view returns (uint64);
    function setMinBaseFee(uint64 _minBaseFee) external;
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
    uint64 internal immutable MIN_BASE_FEE;
    uint64 internal immutable NEW_MIN_BASE_FEE;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        GAS_LIMIT = uint64(vm.envUint("OLD_GAS_LIMIT"));
        NEW_GAS_LIMIT = uint64(vm.envUint("NEW_GAS_LIMIT"));

        ELASTICITY = uint32(vm.envUint("OLD_ELASTICITY"));
        NEW_ELASTICITY = uint32(vm.envUint("NEW_ELASTICITY"));

        DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("OLD_DA_FOOTPRINT_GAS_SCALAR"));
        NEW_DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("NEW_DA_FOOTPRINT_GAS_SCALAR"));

        MIN_BASE_FEE = uint64(vm.envUint("OLD_MIN_BASE_FEE"));
        NEW_MIN_BASE_FEE = uint64(vm.envUint("NEW_MIN_BASE_FEE"));

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
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).minBaseFee(), NEW_MIN_BASE_FEE, "Min Base Fee mismatch");
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        if (
            GAS_LIMIT != ISystemConfig(SYSTEM_CONFIG).gasLimit()
                || ELASTICITY != ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity()
                || DA_FOOTPRINT_GAS_SCALAR != ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar()
                || MIN_BASE_FEE != ISystemConfig(SYSTEM_CONFIG).minBaseFee()
        ) {
            // Override SystemConfig state to the expected "from" values so simulations succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            // Prepare three storage overrides for SystemConfig
            Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](3);

            // Load current packed gas config (slot 0x68) and replace only the lower 64 bits with GAS_LIMIT
            bytes32 gasConfigSlotKey = bytes32(uint256(0x68));
            uint256 gasConfigWord = uint256(vm.load(SYSTEM_CONFIG, gasConfigSlotKey));
            uint256 updatedGasConfigWord = (gasConfigWord & ~uint256(0xffffffffffffffff)) | uint256(GAS_LIMIT);
            storageOverrides[0] =
                Simulation.StorageOverride({key: gasConfigSlotKey, value: bytes32(updatedGasConfigWord)});

            // Deterministically set EIP-1559 params and DA Footprint Gas Scalar (slot 0x6a)
            bytes32 eip1559SlotKey = bytes32(uint256(0x6a));
            uint256 composedEip1559Word =
                (uint256(DA_FOOTPRINT_GAS_SCALAR) << 160) | (uint256(ELASTICITY) << 32) | uint256(DENOMINATOR);
            storageOverrides[1] = Simulation.StorageOverride({key: eip1559SlotKey, value: bytes32(composedEip1559Word)});

            // Load current packed slot 0x6c (superchainConfig address + minBaseFee) and replace minBaseFee
            bytes32 minBaseFeeSlotKey = bytes32(uint256(0x6c));
            uint256 minBaseFeeSlotWord = uint256(vm.load(SYSTEM_CONFIG, minBaseFeeSlotKey));
            // minBaseFee is stored in the upper 64 bits after the 160-bit address
            // Mask: keep lower 160 bits (address), clear upper 96 bits
            uint256 addressMask = (1 << 160) - 1;
            uint256 updatedMinBaseFeeWord = (minBaseFeeSlotWord & addressMask) | (uint256(MIN_BASE_FEE) << 160);
            storageOverrides[2] =
                Simulation.StorageOverride({key: minBaseFeeSlotKey, value: bytes32(updatedMinBaseFeeWord)});

            stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
            return stateOverrides;
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](4);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setEIP1559Params, (DENOMINATOR, NEW_ELASTICITY)),
            value: 0
        });

        calls[1] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setGasLimit, (NEW_GAS_LIMIT)),
            value: 0
        });

        calls[2] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setDAFootprintGasScalar, (NEW_DA_FOOTPRINT_GAS_SCALAR)),
            value: 0
        });

        calls[3] = IMulticall3.Call3Value({
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
