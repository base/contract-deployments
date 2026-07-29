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
import {Vm} from "forge-std/Vm.sol";

// This script will be signed ahead of Ecotone but is not planned for execution.
// If something goes wrong with the hardfork, we can rollback the config by executing
// this pre-signed transaction.
contract RollbackGasConfig is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint256 internal FALLBACK_SCALAR = vm.envUint("FALLBACK_SCALAR");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        require(SystemConfig(L1_SYSTEM_CONFIG).scalar() == FALLBACK_SCALAR);
        require(SystemConfig(L1_SYSTEM_CONFIG).overhead() == 0);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(
                SystemConfig.setGasConfig,
                (
                    0, // overhead is not used post Ecotome
                    FALLBACK_SCALAR
                )
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SYSTEM_CONFIG_OWNER;
    }

    function _getNonce(IGnosisSafe safe) internal view override returns (uint256 nonce) {
        uint256 _nonce = safe.nonce();
        console.log("Safe current nonce:", _nonce);
        console.log("Incrememnting by 1 to account for planned `Update` tx");
        return _nonce + 1;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}
