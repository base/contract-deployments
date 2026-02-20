// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function superchainConfig() external view returns (address);
}

interface ISuperchainConfig {
    function pause(address _identifier) external;
    function paused() external view returns (bool);
}

contract PauseSuperchainConfig is MultisigScript {
    address public immutable INCIDENT_SAFE = vm.envAddress("INCIDENT_SAFE");
    address public immutable SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        address superchainConfig = ISystemConfig(SYSTEM_CONFIG).superchainConfig();

        calls[0] = IMulticall3.Call3Value({
            target: superchainConfig,
            allowFailure: false,
            callData: abi.encodeCall(ISuperchainConfig.pause, (address(0))),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        address superchainConfig = ISystemConfig(SYSTEM_CONFIG).superchainConfig();
        bool paused = ISuperchainConfig(superchainConfig).paused();
        require(paused == true, "PauseSuperchainConfig: chain is not paused");
    }

    function _ownerSafe() internal view override returns (address) {
        return INCIDENT_SAFE;
    }
}
