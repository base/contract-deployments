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
import {Vm} from "forge-std/Vm.sol";

contract UpdateGasConfig is MultisigBuilder {
    address internal SYSTEM_CONFIG_OWNER = vm.envAddress("SYSTEM_CONFIG_OWNER");
    address internal L1_SYSTEM_CONFIG = vm.envAddress("L1_SYSTEM_CONFIG_ADDRESS");
    uint256 internal SCALAR = vm.envUint("SCALAR");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        require(SystemConfig(L1_SYSTEM_CONFIG).scalar() == SCALAR);
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
                    0, // overhead is not used post Ecotone
                    SCALAR
                )
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SYSTEM_CONFIG_OWNER;
    }

    function _addOverrides(address _safe) internal pure override returns (SimulationStateOverride memory) {
        return overrideSafeThresholdAndOwner(_safe, DEFAULT_SENDER);
    }
}
