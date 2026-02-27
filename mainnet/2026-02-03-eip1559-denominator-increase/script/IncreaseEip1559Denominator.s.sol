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
}

contract IncreaseEip1559DenominatorScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint32 internal immutable DENOMINATOR;
    uint32 internal immutable NEW_DENOMINATOR;
    uint32 internal immutable ELASTICITY;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        DENOMINATOR = uint32(vm.envUint("OLD_DENOMINATOR"));
        NEW_DENOMINATOR = uint32(vm.envUint("NEW_DENOMINATOR"));

        ELASTICITY = ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), NEW_DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), ELASTICITY, "Elasticity mismatch");
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        if (DENOMINATOR != ISystemConfig(SYSTEM_CONFIG).eip1559Denominator()) {
            // Override SystemConfig state to the expected "from" values so simulations succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            // Prepare one storage override for SystemConfig
            Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);

            // Load current packed EIP-1559 params (slot 0x6a) and replace only the lower 32 bits with DENOMINATOR
            bytes32 eip1559SlotKey = bytes32(uint256(0x6a));
            uint256 existingEip1559Word = uint256(vm.load(SYSTEM_CONFIG, eip1559SlotKey));
            uint256 updatedEip1559Word = (existingEip1559Word & ~uint256(0xffffffff)) | uint256(DENOMINATOR);
            storageOverrides[0] = Simulation.StorageOverride({key: eip1559SlotKey, value: bytes32(updatedEip1559Word)});

            stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
            return stateOverrides;
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setEIP1559Params, (NEW_DENOMINATOR, ELASTICITY)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
