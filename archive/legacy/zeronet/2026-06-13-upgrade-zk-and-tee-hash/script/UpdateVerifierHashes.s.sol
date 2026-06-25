// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {AnchorStateRegistry} from "@base-contracts/src/L1/proofs/AnchorStateRegistry.sol";
import {GameType, Hash, Proposal} from "@base-contracts/src/libraries/bridge/Types.sol";

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
/// in the DisputeGameFactory to the newly deployed AggregateVerifier carrying updated verifier hashes.
contract UpdateVerifierHashes is MultisigScript {
    // Task config from .env.
    address internal immutable ownerSafeEnv;
    address internal immutable proxyAdminEnv;
    address internal immutable systemConfigEnv;
    address internal immutable anchorStateRegistryProxyEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;
    bytes32 internal immutable startingAnchorRootEnv;
    uint256 internal immutable startingAnchorL2BlockNumberEnv;

    // Live onchain state.
    address internal immutable currentAggregateVerifier;
    address internal immutable currentAnchorStateRegistryImpl;
    uint256 internal immutable currentAsrDisputeGameFinalityDelaySeconds;
    uint8 internal immutable currentAsrInitVersion;

    // Deployment outputs produced by EOA scripts and read from addresses.json.
    address internal immutable nextAggregateVerifier;
    address internal immutable nextAnchorStateRegistryImpl;
    GameType internal immutable nextGameType;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        startingAnchorRootEnv = vm.envBytes32("STARTING_ANCHOR_ROOT");
        startingAnchorL2BlockNumberEnv = vm.envUint("STARTING_ANCHOR_L2_BLOCK_NUMBER");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);

        AnchorStateRegistry currentAsr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        currentAsrDisputeGameFinalityDelaySeconds = currentAsr.disputeGameFinalityDelaySeconds();
        currentAsrInitVersion = currentAsr.initVersion();

        vm.prank(proxyAdminEnv);
        currentAnchorStateRegistryImpl = IProxy(anchorStateRegistryProxyEnv).implementation();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        nextAnchorStateRegistryImpl = vm.parseJsonAddress({json: json, key: ".anchorStateRegistryImpl"});
        nextGameType = nextAggregateVerifier == address(0)
            ? GameType.wrap(0)
            : AggregateVerifier(nextAggregateVerifier).gameType();
    }

    function setUp() public view {
        require(ownerSafeEnv != address(0), "owner safe not set");
        require(proxyAdminEnv != address(0), "proxy admin not set");
        require(systemConfigEnv != address(0), "system config not set");
        require(anchorStateRegistryProxyEnv != address(0), "asr proxy not set");
        require(disputeGameFactoryProxyEnv != address(0), "dgf proxy not set");
        require(IProxyAdmin(proxyAdminEnv).owner() == ownerSafeEnv, "proxy admin owner mismatch");
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");
        require(nextAnchorStateRegistryImpl != address(0), "next asr impl not set");
        require(nextAnchorStateRegistryImpl != currentAnchorStateRegistryImpl, "next asr impl equals current");
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");
        require(startingAnchorRootEnv != bytes32(0), "starting anchor root not set");
        require(startingAnchorL2BlockNumberEnv != 0, "starting anchor block not set");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        require(
            address(currentAggregate.anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "current aggregate asr mismatch"
        );
        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");

        _assertUpdatedHashes(nextAggregate);
        _assertImmutableContinuity(currentAggregate, nextAggregate);

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

        _assertUpdatedHashes(nextAggregate);
        _assertImmutableContinuity(currentAggregate, nextAggregate);
    }

    function _assertUpdatedHashes(AggregateVerifier nextAggregate) internal view {
        require(nextAggregate.TEE_IMAGE_HASH() == teeImageHashEnv, "next aggregate tee image hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");
    }

    function _assertImmutableContinuity(AggregateVerifier currentAggregate, AggregateVerifier nextAggregate)
        internal
        view
    {
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
        require(
            address(nextAggregate.ZK_VERIFIER()) == address(currentAggregate.ZK_VERIFIER()),
            "next aggregate zk verifier mismatch"
        );
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
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
