// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";

contract UpdateGaslimit is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint64 internal GAS_LIMIT = uint64(vm.envUint("GAS_LIMIT"));

    function _postCheck() internal view override {
        require(SystemConfig(L1_SYSTEM_CONFIG).gasLimit() == GAS_LIMIT);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: L1_SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(SystemConfig.setGasLimit, (GAS_LIMIT))
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
