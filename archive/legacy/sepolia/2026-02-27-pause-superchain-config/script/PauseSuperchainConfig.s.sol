// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

interface ISystemConfig {
    function superchainConfig() external view returns (address);
}

interface ISuperchainConfig {
    function pause(address _identifier) external;
    function paused(address) external view returns (bool);
}

contract PauseSuperchainConfig is MultisigScript {
    address public immutable INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG");
    address public immutable SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        address superchainConfig = ISystemConfig(SYSTEM_CONFIG).superchainConfig();

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: superchainConfig,
            data: abi.encodeCall(ISuperchainConfig.pause, (address(0))),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        address superchainConfig = ISystemConfig(SYSTEM_CONFIG).superchainConfig();
        bool paused = ISuperchainConfig(superchainConfig).paused(address(0));
        require(paused == true, "PauseSuperchainConfig: chain is not paused");
    }

    function _ownerSafe() internal view override returns (address) {
        return INCIDENT_MULTISIG;
    }
}
