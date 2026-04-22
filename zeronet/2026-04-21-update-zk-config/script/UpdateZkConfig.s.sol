// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType, Hash, Proposal} from "@base-contracts/src/dispute/lib/Types.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
}

interface IProxy {
    function implementation() external view returns (address);
}

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Resets the AnchorStateRegistry starting anchor and updates the live multiproof implementation
/// in the DisputeGameFactory to the newly deployed AggregateVerifier carrying the new ZK config.
contract UpdateZkConfig is MultisigScript {
    // Task config from .env.
    address internal ownerSafeEnv;
    address internal proxyAdminEnv;
    address internal systemConfigEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal sp1VerifierEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;
    bytes32 internal startingAnchorRootEnv;
    uint256 internal startingAnchorL2BlockNumberEnv;

    // Live onchain state.
    address internal currentAggregateVerifier;
    address internal currentZkVerifier;
    address internal currentAnchorStateRegistryImpl;
    uint256 internal currentAsrDisputeGameFinalityDelaySeconds;
    uint8 internal currentAsrInitVersion;

    // Deployment outputs produced by the EOA scripts and read from addresses.json.
    address internal nextAggregateVerifier;
    address internal nextZkVerifier;
    address internal nextAnchorStateRegistryImpl;

    // AggregateVerifier metadata used by the multisig update call and post-checks.
    GameType internal nextGameType;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierEnv = vm.envAddress("SP1_VERIFIER");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        require(IProxyAdmin(proxyAdminEnv).owner() == ownerSafeEnv, "proxy admin owner mismatch");
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        require(
            address(currentAggregate.anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "current aggregate asr mismatch"
        );
        currentZkVerifier = address(currentAggregate.ZK_VERIFIER());

        AnchorStateRegistry currentAsr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        currentAsrDisputeGameFinalityDelaySeconds = currentAsr.disputeGameFinalityDelaySeconds();
        currentAsrInitVersion = currentAsr.initVersion();

        vm.prank(proxyAdminEnv);
        currentAnchorStateRegistryImpl = IProxy(anchorStateRegistryProxyEnv).implementation();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});
        nextAnchorStateRegistryImpl = vm.parseJsonAddress({json: json, key: ".anchorStateRegistryImpl"});

        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");
        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(nextZkVerifier != currentZkVerifier, "next zk verifier equals current");
        require(nextAnchorStateRegistryImpl != address(0), "next asr impl not set");
        require(nextAnchorStateRegistryImpl != currentAnchorStateRegistryImpl, "next asr impl equals current");
        require(sp1VerifierEnv != address(0), "sp1 verifier not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");
        require(startingAnchorRootEnv != bytes32(0), "starting anchor root not set");
        require(startingAnchorL2BlockNumberEnv != 0, "starting anchor block not set");

        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);
        nextGameType = nextAggregate.gameType();

        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");
        require(
            address(nextAggregate.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "next aggregate asr mismatch"
        );
        require(
            address(nextAggregate.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "next aggregate dgf mismatch"
        );
        require(
            address(nextAggregate.DELAYED_WETH()) == address(currentAggregate.DELAYED_WETH()),
            "next aggregate delayed weth mismatch"
        );
        require(
            address(nextAggregate.TEE_VERIFIER()) == address(currentAggregate.TEE_VERIFIER()),
            "next aggregate tee verifier mismatch"
        );
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(
            nextAggregate.TEE_IMAGE_HASH() == currentAggregate.TEE_IMAGE_HASH(),
            "next aggregate tee image hash mismatch"
        );
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");
        require(nextAggregate.CONFIG_HASH() == currentAggregate.CONFIG_HASH(), "next aggregate config hash mismatch");
        require(nextAggregate.L2_CHAIN_ID() == currentAggregate.L2_CHAIN_ID(), "next aggregate l2 chain id mismatch");
        require(
            nextAggregate.BLOCK_INTERVAL() == currentAggregate.BLOCK_INTERVAL(),
            "next aggregate block interval mismatch"
        );
        require(
            nextAggregate.INTERMEDIATE_BLOCK_INTERVAL() == currentAggregate.INTERMEDIATE_BLOCK_INTERVAL(),
            "next aggregate intermediate interval mismatch"
        );
        require(
            nextAggregate.PROOF_THRESHOLD() == currentAggregate.PROOF_THRESHOLD(),
            "next aggregate proof threshold mismatch"
        );
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "next zk verifier asr mismatch"
        );
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "next zk verifier sp1 mismatch");

        AnchorStateRegistry nextAsrImpl = AnchorStateRegistry(nextAnchorStateRegistryImpl);
        require(
            nextAsrImpl.disputeGameFinalityDelaySeconds() == currentAsrDisputeGameFinalityDelaySeconds,
            "next asr finality delay mismatch"
        );
        require(nextAsrImpl.initVersion() == currentAsrInitVersion + 1, "next asr init version mismatch");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    anchorStateRegistryProxyEnv,
                    nextAnchorStateRegistryImpl,
                    abi.encodeCall(
                        AnchorStateRegistry.initialize,
                        (
                            ISystemConfig(systemConfigEnv),
                            IDisputeGameFactory(disputeGameFactoryProxyEnv),
                            Proposal({
                                root: Hash.wrap(startingAnchorRootEnv), l2SequenceNumber: startingAnchorL2BlockNumberEnv
                            }),
                            nextGameType
                        )
                    )
                )
            ),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (nextGameType, nextAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);
        AnchorStateRegistry asr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        Proposal memory startingAnchor = asr.getStartingAnchorRoot();
        (Hash currentAnchorRoot, uint256 currentAnchorL2BlockNumber) = asr.getAnchorRoot();

        vm.prank(proxyAdminEnv);
        require(
            IProxy(anchorStateRegistryProxyEnv).implementation() == nextAnchorStateRegistryImpl, "asr impl mismatch"
        );

        require(address(asr.systemConfig()) == systemConfigEnv, "asr system config mismatch");
        require(address(asr.disputeGameFactory()) == disputeGameFactoryProxyEnv, "asr dgf mismatch");
        require(address(asr.anchorGame()) == address(0), "asr anchor game not reset");
        require(Hash.unwrap(startingAnchor.root) == startingAnchorRootEnv, "asr starting anchor root mismatch");
        require(startingAnchor.l2SequenceNumber == startingAnchorL2BlockNumberEnv, "asr starting anchor block mismatch");
        require(Hash.unwrap(currentAnchorRoot) == startingAnchorRootEnv, "asr current anchor root mismatch");
        require(currentAnchorL2BlockNumber == startingAnchorL2BlockNumberEnv, "asr current anchor block mismatch");
        require(GameType.unwrap(asr.respectedGameType()) == GameType.unwrap(gameTypeEnv), "asr game type mismatch");
        require(
            asr.disputeGameFinalityDelaySeconds() == currentAsrDisputeGameFinalityDelaySeconds,
            "asr finality delay mismatch"
        );
        require(asr.initVersion() == currentAsrInitVersion + 1, "asr init version mismatch");

        require(dgf.gameImpls(nextGameType) == nextAggregateVerifier, "dgf aggregate verifier mismatch");
        require(
            address(nextAggregate.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "next aggregate asr mismatch"
        );
        require(
            address(nextAggregate.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "next aggregate dgf mismatch"
        );
        require(
            address(nextAggregate.DELAYED_WETH()) == address(currentAggregate.DELAYED_WETH()),
            "next aggregate delayed weth mismatch"
        );
        require(
            address(nextAggregate.TEE_VERIFIER()) == address(currentAggregate.TEE_VERIFIER()),
            "next aggregate tee verifier mismatch"
        );
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(
            nextAggregate.TEE_IMAGE_HASH() == currentAggregate.TEE_IMAGE_HASH(),
            "next aggregate tee image hash mismatch"
        );
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");
        require(nextAggregate.CONFIG_HASH() == currentAggregate.CONFIG_HASH(), "next aggregate config hash mismatch");
        require(nextAggregate.L2_CHAIN_ID() == currentAggregate.L2_CHAIN_ID(), "next aggregate l2 chain id mismatch");
        require(
            nextAggregate.BLOCK_INTERVAL() == currentAggregate.BLOCK_INTERVAL(),
            "next aggregate block interval mismatch"
        );
        require(
            nextAggregate.INTERMEDIATE_BLOCK_INTERVAL() == currentAggregate.INTERMEDIATE_BLOCK_INTERVAL(),
            "next aggregate intermediate interval mismatch"
        );
        require(
            nextAggregate.PROOF_THRESHOLD() == currentAggregate.PROOF_THRESHOLD(),
            "next aggregate proof threshold mismatch"
        );
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "next zk verifier asr mismatch"
        );
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "next zk verifier sp1 mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
