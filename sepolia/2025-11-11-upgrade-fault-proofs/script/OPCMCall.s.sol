// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

interface IOPCM {
    struct OpChainConfig {
        address systemConfigProxy;
        address proxyAdmin;
        bytes32 absolutePrestate;
    }

    function upgrade(OpChainConfig[] memory _opChainConfigs) external;
}

/// @notice This script updates the FaultDisputeGame and PermissionedDisputeGame implementations in the
///         DisputeGameFactory contract.
contract OPCMCall is MultisigScript {
    address public immutable OWNER_SAFE;
    address public immutable OPCM_ADDRESS;
    address public immutable PROXY_ADMIN;
    address public immutable SYSTEM_CONFIG;
    bytes32 public immutable ABSOLUTE_PRESTATE;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        OPCM_ADDRESS = vm.envAddress("OPCM_ADDR");
        PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
        ABSOLUTE_PRESTATE = vm.envBytes32("ABSOLUTE_PRESTATE");
    }

    // Confirm the stored implementations are updated and the anchor states still exist.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        IOPCM.OpChainConfig[] memory cfg = new IOPCM.OpChainConfig[](1);
        cfg[0] = IOPCM.OpChainConfig({
            systemConfigProxy: SYSTEM_CONFIG, proxyAdmin: PROXY_ADMIN, absolutePrestate: ABSOLUTE_PRESTATE
        });

        calls[0] = IMulticall3.Call3Value({
            target: address(OPCM_ADDRESS), allowFailure: false, callData: abi.encodeCall(IOPCM.upgrade, (cfg)), value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _useMulticall() internal pure override returns (bool) {
        return false;
    }
}
