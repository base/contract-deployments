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
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

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

contract ActivateMultiproofStack is MultisigScript {
    uint32 internal constant CANNON_GAME_TYPE = 0;

    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal optimismPortalEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal sp1VerifierEnv;

    uint32 internal gameTypeEnv;
    uint256 internal initBondEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;
    bytes32 internal configHashEnv;
    uint256 internal l2ChainIdEnv;
    uint256 internal blockIntervalEnv;
    uint256 internal intermediateBlockIntervalEnv;
    uint256 internal proofThresholdEnv;
    uint256 internal proofMaturityDelaySecondsEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryManagerEnv;
    address internal proposerEnv;
    address internal challengerEnv;

    address internal newAggregateVerifier;
    address internal newTeeVerifier;
    address internal newZkVerifier;
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
        sp1VerifierEnv = vm.envAddress("SP1_VERIFIER");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        initBondEnv = vm.envUint("INIT_BOND");
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");
        l2ChainIdEnv = vm.envUint("L2_CHAIN_ID");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");
        proofThresholdEnv = vm.envUint("PROOF_THRESHOLD");
        proofMaturityDelaySecondsEnv = vm.envUint("PROOF_MATURITY_DELAY_SECONDS");
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryManagerEnv = vm.envAddress("TEE_PROVER_REGISTRY_MANAGER");
        proposerEnv = vm.envAddress("PROPOSER");
        challengerEnv = vm.envAddress("CHALLENGER");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        newAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        newTeeVerifier = vm.parseJsonAddress({json: json, key: ".teeVerifier"});
        newZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});
        newOptimismPortalImpl = vm.parseJsonAddress({json: json, key: ".optimismPortal2Impl"});
        newDgfImpl = vm.parseJsonAddress({json: json, key: ".disputeGameFactoryImpl"});
        newAsrImpl = vm.parseJsonAddress({json: json, key: ".anchorStateRegistryImpl"});
        newTeeProverRegistryImpl = vm.parseJsonAddress({json: json, key: ".teeProverRegistryImpl"});
        newTeeProverRegistryProxy = vm.parseJsonAddress({json: json, key: ".teeProverRegistryProxy"});
        newDelayedWethImpl = vm.parseJsonAddress({json: json, key: ".delayedWETHImpl"});
        newDelayedWethProxy = vm.parseJsonAddress({json: json, key: ".delayedWETHProxy"});

        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv,
            "DGF owner != PROXY_ADMIN_OWNER"
        );
        require(ISystemConfig(systemConfigEnv).guardian() == ownerSafeEnv, "Guardian != PROXY_ADMIN_OWNER");

        _checkAggregateVerifier();
        _checkZkVerifier();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](7);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (optimismPortalEnv, newOptimismPortalImpl)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (disputeGameFactoryProxyEnv, newDgfImpl)),
            value: 0
        });

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

        calls[3] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (GameType.wrap(gameTypeEnv), newAggregateVerifier, "")
            ),
            value: 0
        });

        calls[4] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setInitBond, (GameType.wrap(gameTypeEnv), initBondEnv)),
            value: 0
        });

        calls[5] = Call({
            operation: Enum.Operation.Call,
            target: anchorStateRegistryProxyEnv,
            data: abi.encodeCall(AnchorStateRegistry.updateRetirementTimestamp, ()),
            value: 0
        });

        calls[6] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (GameType.wrap(CANNON_GAME_TYPE), address(0), "")
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        _checkProxyUpgrades();
        _checkAnchorStateRegistry();
        _checkTeeProverRegistryProxy();
        _checkDelayedWethProxy();
        _checkDisputeGameFactory();
        _checkAggregateVerifier();
        _checkZkVerifier();
    }

    function _checkProxyUpgrades() internal {
        vm.prank(proxyAdminEnv);
        require(IProxy(optimismPortalEnv).implementation() == newOptimismPortalImpl, "portal impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(disputeGameFactoryProxyEnv).implementation() == newDgfImpl, "dgf impl mismatch");
        vm.prank(proxyAdminEnv);
        require(IProxy(anchorStateRegistryProxyEnv).implementation() == newAsrImpl, "asr impl mismatch");
    }

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
        require(
            OptimismPortal2(payable(optimismPortalEnv)).proofMaturityDelaySeconds() == proofMaturityDelaySecondsEnv,
            "portal proof maturity delay mismatch"
        );
    }

    function _checkTeeProverRegistryProxy() internal {
        vm.prank(proxyAdminEnv);
        require(
            IProxy(newTeeProverRegistryProxy).implementation() == newTeeProverRegistryImpl, "tee registry impl mismatch"
        );

        TEEProverRegistry registry = TEEProverRegistry(newTeeProverRegistryProxy);
        require(registry.owner() == teeProverRegistryOwnerEnv, "tee registry owner mismatch");
        require(registry.manager() == teeProverRegistryManagerEnv, "tee registry manager mismatch");
        require(GameType.unwrap(registry.gameType()) == gameTypeEnv, "tee registry game type mismatch");
        require(registry.isValidProposer(proposerEnv), "tee registry proposer mismatch");
        require(registry.isValidProposer(challengerEnv), "tee registry challenger mismatch");
    }

    function _checkDelayedWethProxy() internal {
        vm.prank(proxyAdminEnv);
        require(IProxy(newDelayedWethProxy).implementation() == newDelayedWethImpl, "delayed weth impl mismatch");
        require(
            address(DelayedWETH(payable(newDelayedWethProxy)).systemConfig()) == systemConfigEnv,
            "delayed weth systemConfig mismatch"
        );
    }

    function _checkDisputeGameFactory() internal view {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(dgf.gameImpls(GameType.wrap(gameTypeEnv)) == newAggregateVerifier, "game impl mismatch");
        require(dgf.gameImpls(GameType.wrap(CANNON_GAME_TYPE)) == address(0), "cannon impl mismatch");
        require(dgf.initBonds(GameType.wrap(gameTypeEnv)) == initBondEnv, "init bond mismatch");
    }

    function _checkAggregateVerifier() internal view {
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);
        require(GameType.unwrap(av.gameType()) == gameTypeEnv, "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "aggregate asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "aggregate dgf mismatch");
        require(address(av.DELAYED_WETH()) == newDelayedWethProxy, "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == newTeeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == newZkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == configHashEnv, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainIdEnv, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == blockIntervalEnv, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockIntervalEnv,
            "aggregate intermediate interval mismatch"
        );
        require(av.PROOF_THRESHOLD() == proofThresholdEnv, "aggregate proof threshold mismatch");
    }

    function _checkZkVerifier() internal view {
        require(address(ZkVerifier(newZkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "zk verifier sp1 mismatch");
        require(
            address(ZkVerifier(newZkVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "zk verifier asr mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
