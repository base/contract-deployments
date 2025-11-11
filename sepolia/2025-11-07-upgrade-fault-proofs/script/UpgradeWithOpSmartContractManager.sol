// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {
    IOPContractsManager,
    ISystemConfig
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {
    OPContractsManager
} from "@eth-optimism-bedrock/src/L1/OPContractsManager.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console} from "forge-std/console.sol";

/// @notice This script deploys new versions of OP contracts using the OP Contract Manager.
contract UpgradeWithOpSmartContractManager is MultisigScript {
    using Strings for address;

    ISystemConfig internal immutable _SYSTEM_CONFIG;
    IOPContractsManager internal immutable _OP_CONTRACT_MANAGER;
    address public immutable OWNER_SAFE;
    Claim immutable CANNON_ABSOLUTE_PRESTATE;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        _SYSTEM_CONFIG = ISystemConfig(vm.envAddress("SYSTEM_CONFIG"));
        // _OP_CONTRACT_MANAGER = IOPContractsManager(vm.envAddress("OP_CONTRACT_MANAGER"));
        CANNON_ABSOLUTE_PRESTATE = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));

        OPContractsManager currentOp = OPContractsManager(vm.envAddress("OP_CONTRACT_MANAGER"));

        OPContractsManager newOP = new OPContractsManager(currentOp.opcmGameTypeAdder(), currentOp.opcmDeployer(), currentOp.opcmUpgrader(), currentOp.opcmInteropMigrator(), currentOp.opcmStandardValidator(), currentOp.superchainConfig(), currentOp.protocolVersions());

        _OP_CONTRACT_MANAGER = IOPContractsManager(address(newOP));
        console.log("hey", address(_OP_CONTRACT_MANAGER));
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IOPContractsManager.OpChainConfig memory baseConfig =
            IOPContractsManager.OpChainConfig(_SYSTEM_CONFIG, CANNON_ABSOLUTE_PRESTATE, Claim.wrap(bytes32(0)));

        IOPContractsManager.OpChainConfig[] memory opChainConfigs = new IOPContractsManager.OpChainConfig[](1);
        opChainConfigs[0] = baseConfig;

        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: address(_OP_CONTRACT_MANAGER),
            allowFailure: false,
            callData: abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
