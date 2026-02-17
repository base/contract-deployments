// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function minBaseFee() external view returns (uint64);
    function setMinBaseFee(uint64 _minBaseFee) external;
}

contract SetMinBaseFeeScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint64 internal immutable MIN_BASE_FEE;
    uint64 internal immutable NEW_MIN_BASE_FEE;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        MIN_BASE_FEE = uint64(vm.envUint("OLD_MIN_BASE_FEE"));
        NEW_MIN_BASE_FEE = uint64(vm.envUint("NEW_MIN_BASE_FEE"));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).minBaseFee(), NEW_MIN_BASE_FEE, "Min base fee mismatch");
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory _stateOverrides) {
        if (MIN_BASE_FEE != ISystemConfig(SYSTEM_CONFIG).minBaseFee()) {
            // Override SystemConfig state to the expected "from" values so simulations succeeds even
            // when the chain already reflects the post-change values (during rollback simulation).

            Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);

            // Update minBaseFee (slot 0x6c)
            // Storage layout (low to high bits):
            //   - superchainConfig (address): bits 0-159
            //   - minBaseFee (uint64): bits 160-223
            // Load existing slot to preserve superchainConfig, then update minBaseFee.
            bytes32 minBaseFeeSlotKey = bytes32(uint256(0x6c));
            uint256 existingMinBaseFeeWord = uint256(vm.load(SYSTEM_CONFIG, minBaseFeeSlotKey));
            uint256 updatedMinBaseFeeWord = (existingMinBaseFeeWord & ((1 << 160) - 1)) | (uint256(MIN_BASE_FEE) << 160);
            storageOverrides[0] =
                Simulation.StorageOverride({key: minBaseFeeSlotKey, value: bytes32(updatedMinBaseFeeWord)});

            stateOverrides[0] = Simulation.StateOverride({contractAddress: SYSTEM_CONFIG, overrides: storageOverrides});
            return stateOverrides;
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
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
