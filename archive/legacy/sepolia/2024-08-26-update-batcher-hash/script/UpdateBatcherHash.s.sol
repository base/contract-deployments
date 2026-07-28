// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Vm} from "forge-std/Vm.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";

contract UpdateBatcherHash is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    address internal NEW_BATCH_SENDER = vm.envAddress("NEW_BATCH_SENDER");

    function _convertAddressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        require(
            SystemConfig(L1_SYSTEM_CONFIG).batcherHash() == _convertAddressToBytes32(NEW_BATCH_SENDER),
            "Rollback Deploy: batcherHash is incorrect"
        );
        console.log("New batcherHash: ");
        console.logBytes32(SystemConfig(L1_SYSTEM_CONFIG).batcherHash());
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        console.log("Current batcherHash: ");
        console.logBytes32(SystemConfig(L1_SYSTEM_CONFIG).batcherHash());
        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(SystemConfig.setBatcherHash, (_convertAddressToBytes32(NEW_BATCH_SENDER)))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SYSTEM_CONFIG_OWNER;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}
