// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {
    IOPContractsManager,
    IOPContractsManagerStandardValidator,
    ISystemConfig,
    IProxyAdmin,
    ISuperchainConfig
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

/// @notice This script deploys new versions of OP contracts using the OP Contract Manager.
contract ExecuteOPCMScript is MultisigScript {
    ISystemConfig internal immutable SYSTEM_CONFIG;
    IOPContractsManager internal immutable OP_CONTRACT_MANAGER;
    address public immutable OWNER_SAFE;
    IProxyAdmin public immutable PROXY_ADMIN;
    Claim immutable CANNON_ABSOLUTE_PRESTATE;

    address internal immutable CHALLENGER;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        PROXY_ADMIN = IProxyAdmin(vm.envAddress("PROXY_ADMIN"));
        SYSTEM_CONFIG = ISystemConfig(vm.envAddress("SYSTEM_CONFIG"));
        OP_CONTRACT_MANAGER = IOPContractsManager(vm.envAddress("OP_CONTRACT_MANAGER"));
        CANNON_ABSOLUTE_PRESTATE = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));
        CHALLENGER = vm.envAddress("CHALLENGER");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IOPContractsManagerStandardValidator.ValidationInput memory input =
            IOPContractsManagerStandardValidator.ValidationInput(
                PROXY_ADMIN, SYSTEM_CONFIG, Claim.unwrap(CANNON_ABSOLUTE_PRESTATE), SYSTEM_CONFIG.l2ChainId()
            );

        IOPContractsManagerStandardValidator.ValidationOverrides memory overrides =
            IOPContractsManagerStandardValidator.ValidationOverrides(OWNER_SAFE, CHALLENGER);

        OP_CONTRACT_MANAGER.validateWithOverrides(input, false, overrides);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IOPContractsManager.OpChainConfig memory baseConfig =
            IOPContractsManager.OpChainConfig(SYSTEM_CONFIG, PROXY_ADMIN, CANNON_ABSOLUTE_PRESTATE);

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

    function _simulationOverrides()
        internal
        view
        virtual
        override
        returns (Simulation.StateOverride[] memory overrides_)
    {
        // Get the superchain config address from the SystemConfig
        ISuperchainConfig superchainConfig = ISuperchainConfig(SYSTEM_CONFIG.superchainConfig());
        IOPContractsManager.Implementations memory impls = OP_CONTRACT_MANAGER.implementations();

        // Mock the implementation slot of the superchain config if the version has not been upgraded yet.
        bytes32 h1 = keccak256(abi.encode(ISuperchainConfig(impls.superchainConfigImpl).version()));
        bytes32 h2 = keccak256(abi.encode(superchainConfig.version()));
        if (h1 != h2) {
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);
            storageOverrides[0] = Simulation.StorageOverride(
                Constants.PROXY_IMPLEMENTATION_ADDRESS, bytes32(uint256(uint160(address(impls.superchainConfigImpl))))
            );

            overrides_ = new Simulation.StateOverride[](1);
            overrides_[0] = Simulation.StateOverride(address(superchainConfig), storageOverrides);
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _useDelegateCall() internal pure override returns (bool) {
        return true;
    }
}
