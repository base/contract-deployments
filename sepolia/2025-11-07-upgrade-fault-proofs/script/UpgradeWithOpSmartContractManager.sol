// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin,
    IDisputeGameFactory,
    IFaultDisputeGame
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

    address oldDelayedWethPermissioned;
    address oldDelayedWethPermissionless;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        PROXY_ADMIN = IProxyAdmin(vm.envAddress("PROXY_ADMIN"));
        _SYSTEM_CONFIG = ISystemConfig(vm.envAddress("SYSTEM_CONFIG"));
        OP_CONTRACT_MANAGER = IOPContractsManager(vm.envAddress("OP_CONTRACT_MANAGER"));
        CANNON_ABSOLUTE_PRESTATE = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));

        IDisputeGameFactory dfg = IDisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        IFaultDisputeGame fdg = IFaultDisputeGame(address(dfg.gameImpls(GameTypes.CANNON)));
        IFaultDisputeGame pfdg = IFaultDisputeGame(address(dfg.gameImpls(GameTypes.PERMISSIONED_CANNON)));
        oldDelayedWethPermissioned = address(pfdg.weth());
        oldDelayedWethPermissionless = address(fdg.weth());
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IOPContractsManager.Implementations memory impls = OP_CONTRACT_MANAGER.implementations();

        // verify proxyadmin address updates
        require(PROXY_ADMIN.getProxyImplementation(address(_SYSTEM_CONFIG)) == impls.systemConfigImpl, "00");
        require(
            PROXY_ADMIN.getProxyImplementation(address(_SYSTEM_CONFIG.optimismPortal())) == impls.optimismPortalImpl,
            "01"
        );
        require(
            PROXY_ADMIN.getProxyImplementation(address(_SYSTEM_CONFIG.optimismMintableERC20Factory()))
                == impls.optimismMintableERC20FactoryImpl,
            "02"
        );
        require(
            PROXY_ADMIN.getProxyImplementation(address(_SYSTEM_CONFIG.disputeGameFactory()))
                == impls.disputeGameFactoryImpl,
            "03"
        );

        ISystemConfig.Addresses memory opChainAddrs = _SYSTEM_CONFIG.getAddresses();
        require(
            PROXY_ADMIN.getProxyImplementation(opChainAddrs.l1CrossDomainMessenger) == impls.l1CrossDomainMessengerImpl,
            "04"
        );
        require(PROXY_ADMIN.getProxyImplementation(opChainAddrs.l1StandardBridge) == impls.l1StandardBridgeImpl, "05");
        require(PROXY_ADMIN.getProxyImplementation(opChainAddrs.l1ERC721Bridge) == impls.l1ERC721BridgeImpl, "06");

        IDisputeGameFactory dfg = IDisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        IFaultDisputeGame fdg = IFaultDisputeGame(address(dfg.gameImpls(GameTypes.CANNON)));
        IFaultDisputeGame pfdg = IFaultDisputeGame(address(dfg.gameImpls(GameTypes.PERMISSIONED_CANNON)));
        Claim fdgAbsolutePrestate = fdg.absolutePrestate();
        Claim pfdgAbsolutePrestate = pfdg.absolutePrestate();

        // verify FaultDisputeGame and PermissionedDisputeGame absolute prestate
        require(Claim.unwrap(fdgAbsolutePrestate) == Claim.unwrap(CANNON_ABSOLUTE_PRESTATE), "07");
        require(Claim.unwrap(pfdgAbsolutePrestate) == Claim.unwrap(CANNON_ABSOLUTE_PRESTATE), "08");

        // verify FaultDisputeGame and PermissionedDisputeGame vm
        require(address(fdg.vm()) == impls.mipsImpl, "09");
        require(address(pfdg.vm()) == impls.mipsImpl, "10");

        // verify DelayedWETH doesn't change
        // https://github.com/ethereum-optimism/optimism/blob/d09c836f818c73ae139f60b717654c4e53712743/packages/contracts-bedrock/src/L1/OPContractsManager.sol#L877
        require(address(fdg.weth()) == oldDelayedWethPermissionless, "11");
        require(address(pfdg.weth()) == oldDelayedWethPermissioned, "12");
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
