// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {
    IOPContractsManager,
    IOPContractsManagerStandardValidator,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

/// @notice This script deploys new versions of OP contracts using the OP Contract Manager.
contract UpgradeWithOpSmartContractManager is MultisigScript {
    ISystemConfig internal immutable _SYSTEM_CONFIG;
    IOPContractsManager internal immutable OP_CONTRACT_MANAGER;
    address public immutable OWNER_SAFE;
    IProxyAdmin public immutable PROXY_ADMIN;
    Claim immutable CANNON_ABSOLUTE_PRESTATE;

    address internal immutable L1_PROXY_ADMIN_OWNER;
    address internal immutable CHALLENGER;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        PROXY_ADMIN = IProxyAdmin(vm.envAddress("PROXY_ADMIN"));
        _SYSTEM_CONFIG = ISystemConfig(vm.envAddress("SYSTEM_CONFIG"));
        OP_CONTRACT_MANAGER = IOPContractsManager(vm.envAddress("OP_CONTRACT_MANAGER"));
        CANNON_ABSOLUTE_PRESTATE = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));
        L1_PROXY_ADMIN_OWNER = vm.envAddress("L1_PROXY_ADMIN_OWNER");
        CHALLENGER = vm.envAddress("CHALLENGER");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IOPContractsManagerStandardValidator.ValidationInput memory input =
            IOPContractsManagerStandardValidator.ValidationInput(
                PROXY_ADMIN, _SYSTEM_CONFIG, Claim.unwrap(CANNON_ABSOLUTE_PRESTATE), _SYSTEM_CONFIG.l2ChainId()
            );

        IOPContractsManagerStandardValidator.ValidationOverrides memory overrides =
            IOPContractsManagerStandardValidator.ValidationOverrides(L1_PROXY_ADMIN_OWNER, CHALLENGER);

        OP_CONTRACT_MANAGER.validateWithOverrides(input, false, overrides);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IOPContractsManager.OpChainConfig memory baseConfig =
            IOPContractsManager.OpChainConfig(_SYSTEM_CONFIG, PROXY_ADMIN, CANNON_ABSOLUTE_PRESTATE);

        IOPContractsManager.OpChainConfig[] memory opChainConfigs = new IOPContractsManager.OpChainConfig[](1);
        opChainConfigs[0] = baseConfig;

        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: address(OP_CONTRACT_MANAGER),
            allowFailure: false,
            callData: abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _useDelegateCall() internal pure override returns (bool) {
        return true;
    }
}
