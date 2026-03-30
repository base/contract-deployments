// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {GameType, Hash, Proposal} from "@base-contracts/src/dispute/lib/Types.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {DelayedWETH} from "@base-contracts/src/dispute/DelayedWETH.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";

interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
}

interface IProxy {
    function implementation() external view returns (address);
}

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function initBonds(GameType gameType) external view returns (uint256);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
    function setInitBond(GameType gameType, uint256 initBond) external;
}

contract UpgradeMultiproofStack is MultisigScript {
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal optimismPortalEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal anchorStateRegistryProxyEnv;

    uint32 internal gameTypeEnv;
    uint256 internal initBondEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    // TEE registry initialization parameters.
    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryManagerEnv;
    address internal teeProposerEnv;
    address internal challengerEnv;

    // Addresses from the facilitator deploy step (addresses.json).
    address internal newAggregateVerifier;
    address internal newOptimismPortalImpl;
    address internal newDgfImpl;
    address internal newAsrImpl;
    address internal newTeeProverRegistryImpl;
    address internal newTeeProverRegistryProxy;
    address internal newDelayedWethImpl;
    address internal newDelayedWethProxy;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        optimismPortalEnv = vm.envAddress("OPTIMISM_PORTAL");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        initBondEnv = vm.envUint("INIT_BOND");
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryManagerEnv = vm.envAddress("TEE_PROVER_REGISTRY_MANAGER");
        teeProposerEnv = vm.envAddress("TEE_PROPOSER");
        challengerEnv = vm.envAddress("CHALLENGER");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newAggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
        newOptimismPortalImpl = vm.parseJsonAddress(json, ".optimismPortal2Impl");
        newDgfImpl = vm.parseJsonAddress(json, ".disputeGameFactoryImpl");
        newAsrImpl = vm.parseJsonAddress(json, ".anchorStateRegistryImpl");
        newTeeProverRegistryImpl = vm.parseJsonAddress(json, ".teeProverRegistryImpl");
        newTeeProverRegistryProxy = vm.parseJsonAddress(json, ".teeProverRegistryProxy");
        newDelayedWethImpl = vm.parseJsonAddress(json, ".delayedWETHImpl");
        newDelayedWethProxy = vm.parseJsonAddress(json, ".delayedWETHProxy");

        // Sanity-check that the executing Safe holds the roles required by the non-ProxyAdmin calls.
        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv,
            "DGF owner != PROXY_ADMIN_OWNER: setImplementation/setInitBond will revert"
        );
        require(
            ISystemConfig(systemConfigEnv).guardian() == ownerSafeEnv,
            "Guardian != PROXY_ADMIN_OWNER: updateRetirementTimestamp will revert"
        );
    }

    /// @dev Builds the ordered batch of calls executed atomically by the owner Safe.
    ///      Ordering constraints:
    ///      - Proxy upgrades must precede any call that depends on new impl logic.
    ///      - TEEProverRegistry and DelayedWETH must be wired before the game type is registered,
    ///        so that game clones can interact with them.
    ///      - `setImplementation` must be registered before the respected game type takes effect
    ///        through the AnchorStateRegistry reinitializer.
    ///      - `updateRetirementTimestamp` retires old games after all wiring is done.
    ///
    ///      Call summary:
    ///      0. Upgrade OptimismPortal2 proxy.
    ///      1. Upgrade DisputeGameFactory proxy.
    ///      2. Upgrade + reinitialize AnchorStateRegistry proxy (sets respectedGameType).
    ///      3. Wire TEEProverRegistry proxy (upgradeAndCall with initialize).
    ///      4. Wire DelayedWETH proxy (upgradeAndCall with initialize).
    ///      5. Register AggregateVerifier in the DisputeGameFactory.
    ///      6. Set the init bond for the multiproof game type.
    ///      7. Retire pre-cutover games.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](8);

        // 0. Upgrade the OptimismPortal2 proxy to the new implementation.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (optimismPortalEnv, newOptimismPortalImpl)),
            value: 0
        });

        // 1. Upgrade the DisputeGameFactory proxy to the new implementation.
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (disputeGameFactoryProxyEnv, newDgfImpl)),
            value: 0
        });

        // 2. Upgrade the AnchorStateRegistry proxy and reinitialize to seed the starting anchor root,
        //    wire the DGF dependency, and set the respected game type.
        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    anchorStateRegistryProxyEnv,
                    newAsrImpl,
                    abi.encodeCall(
                        AnchorStateRegistry.initialize,
                        (
                            ISystemConfig(systemConfigEnv),
                            IDisputeGameFactory(disputeGameFactoryProxyEnv),
                            Proposal({
                                root: Hash.wrap(startingAnchorRootEnv), l2SequenceNumber: startingAnchorL2BlockNumberEnv
                            }),
                            GameType.wrap(gameTypeEnv)
                        )
                    )
                )
            ),
            value: 0
        });

        // 3. Wire the TEEProverRegistry proxy: set its implementation and initialize owner, manager,
        //    initial valid proposers, and game type in one atomic call.
        calls[3] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (newTeeProverRegistryProxy, newTeeProverRegistryImpl, _teeRegistryInitData())
            ),
            value: 0
        });

        // 4. Wire the DelayedWETH proxy: set its implementation and initialize it with the existing SystemConfig.
        calls[4] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    newDelayedWethProxy,
                    newDelayedWethImpl,
                    abi.encodeCall(DelayedWETH.initialize, (ISystemConfig(systemConfigEnv)))
                )
            ),
            value: 0
        });

        // 5. Register the newly deployed AggregateVerifier as the implementation for the configured multiproof
        //      game type in the DisputeGameFactory.
        calls[5] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (GameType.wrap(gameTypeEnv), newAggregateVerifier, "")
            ),
            value: 0
        });

        // 6. Set the init bond required to create games of the new multiproof type.
        calls[6] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setInitBond, (GameType.wrap(gameTypeEnv), initBondEnv)),
            value: 0
        });

        // 7. Retire any pre-cutover games so older disputes cannot remain respected
        //    after the new multiproof configuration is activated.
        calls[7] = Call({
            operation: Enum.Operation.Call,
            target: anchorStateRegistryProxyEnv,
            data: abi.encodeCall(AnchorStateRegistry.updateRetirementTimestamp, ()),
            value: 0
        });

        return calls;
    }

    /// @dev Builds the initialization payload used when wiring the TEEProverRegistry proxy.
    ///      The registry is initialized with:
    ///      1. `TEE_PROVER_REGISTRY_OWNER` as owner.
    ///      2. `TEE_PROVER_REGISTRY_MANAGER` as manager.
    ///      3. Two initial valid proposers: `TEE_PROPOSER` and `CHALLENGER`.
    ///      4. The multiproof game type, so signer validity resolves against the correct AggregateVerifier.
    /// @return The encoded call to TEEProverRegistry.initialize.
    function _teeRegistryInitData() internal view returns (bytes memory) {
        address[] memory initialProposers = new address[](2);
        initialProposers[0] = teeProposerEnv;
        initialProposers[1] = challengerEnv;
        return abi.encodeCall(
            TEEProverRegistry.initialize,
            (teeProverRegistryOwnerEnv, teeProverRegistryManagerEnv, initialProposers, GameType.wrap(gameTypeEnv))
        );
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        _checkProxyUpgrades();
        _checkAnchorStateRegistry();
        _checkTeeProverRegistryProxy();
        _checkDelayedWethProxy();
        _checkDisputeGameFactory();
    }

    /// @dev Validates that every existing L1 proxy now points to its new implementation.
    ///      1. Check that OptimismPortal2 proxy implementation equals the deployed impl.
    ///      2. Check that DisputeGameFactory proxy implementation equals the deployed impl.
    ///      3. Check that AnchorStateRegistry proxy implementation equals the deployed impl.
    function _checkProxyUpgrades() internal {
        vm.prank(proxyAdminEnv);
        require(IProxy(optimismPortalEnv).implementation() == newOptimismPortalImpl, "portal impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(disputeGameFactoryProxyEnv).implementation() == newDgfImpl, "dgf impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(anchorStateRegistryProxyEnv).implementation() == newAsrImpl, "asr impl mismatch");
    }

    /// @dev Validates the AnchorStateRegistry reinitialization and cutover state.
    ///      1. Check that systemConfig matches the .env value.
    ///      2. Check that disputeGameFactory matches the .env value.
    ///      3. Check that startingAnchorRoot matches the .env value.
    ///      4. Check that the starting L2 sequence number matches the .env value.
    ///      5. Check that respectedGameType is set to the multiproof game type.
    ///      6. Check that retirementTimestamp equals block.timestamp.
    ///      7. Check that OptimismPortal2 still references this ASR proxy.
    function _checkAnchorStateRegistry() internal view {
        AnchorStateRegistry asr = AnchorStateRegistry(anchorStateRegistryProxyEnv);

        require(address(asr.systemConfig()) == systemConfigEnv, "asr system config mismatch");
        require(address(asr.disputeGameFactory()) == disputeGameFactoryProxyEnv, "asr dgf mismatch");

        Proposal memory startingAnchor = asr.getStartingAnchorRoot();
        require(Hash.unwrap(startingAnchor.root) == startingAnchorRootEnv, "anchor root mismatch");
        require(startingAnchor.l2SequenceNumber == startingAnchorL2BlockNumberEnv, "anchor block mismatch");
        require(GameType.unwrap(asr.respectedGameType()) == gameTypeEnv, "respected game type mismatch");
        require(asr.retirementTimestamp() == uint64(block.timestamp), "retirement timestamp mismatch");
        require(
            address(OptimismPortal2(payable(optimismPortalEnv)).anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "portal asr mismatch"
        );
    }

    /// @dev Validates the TEEProverRegistry proxy after upgradeAndCall.
    ///      1. Check that the proxy implementation is set to the deployed impl.
    ///      2. Check that owner is set to TEE_PROVER_REGISTRY_OWNER.
    ///      3. Check that manager is set to TEE_PROVER_REGISTRY_MANAGER.
    ///      4. Check that gameType is set to the multiproof game type.
    ///      5. Check that TEE_PROPOSER is flagged as valid.
    ///      6. Check that the challenger is flagged as valid.
    function _checkTeeProverRegistryProxy() internal {
        vm.prank(proxyAdminEnv);
        require(
            IProxy(newTeeProverRegistryProxy).implementation() == newTeeProverRegistryImpl, "tee registry impl mismatch"
        );

        TEEProverRegistry registry = TEEProverRegistry(newTeeProverRegistryProxy);
        require(registry.owner() == teeProverRegistryOwnerEnv, "tee registry owner mismatch");
        require(registry.manager() == teeProverRegistryManagerEnv, "tee registry manager mismatch");
        require(GameType.unwrap(registry.gameType()) == gameTypeEnv, "tee registry game type mismatch");
        require(registry.isValidProposer(teeProposerEnv), "tee registry proposer mismatch");
        require(registry.isValidProposer(challengerEnv), "tee registry challenger mismatch");
    }

    /// @dev Validates the DelayedWETH proxy after upgradeAndCall.
    ///      1. Check that the proxy implementation is set to the deployed impl.
    ///      2. Check that systemConfig is initialized to the existing SystemConfig.
    function _checkDelayedWethProxy() internal {
        vm.prank(proxyAdminEnv);
        require(IProxy(newDelayedWethProxy).implementation() == newDelayedWethImpl, "delayed weth impl mismatch");
        require(
            address(DelayedWETH(payable(newDelayedWethProxy)).systemConfig()) == systemConfigEnv,
            "delayed weth systemConfig mismatch"
        );
    }

    /// @dev Validates the DisputeGameFactory configuration for the new multiproof game type.
    ///      1. Check that the game implementation is set to the deployed AggregateVerifier.
    ///      2. Check that the init bond matches the .env value.
    function _checkDisputeGameFactory() internal view {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(dgf.gameImpls(GameType.wrap(gameTypeEnv)) == newAggregateVerifier, "game impl mismatch");
        require(dgf.initBonds(GameType.wrap(gameTypeEnv)) == initBondEnv, "init bond mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
