// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";
import {ProtocolVersions} from "@base-contracts/src/L1/ProtocolVersions.sol";

/// @notice Deploys the Cobalt implementations that base/contracts compiles at 999999 optimizer runs.
/// @dev AggregateVerifier binds PROTOCOL_VERSIONS as a constructor immutable, so it must be
///      redeployed for the registry to take effect and the proxy from DeployCobaltCoreImpls must
///      already exist. Only the proof program hashes and the schedule config are supplied; every
///      other constructor argument is read back from the implementation currently registered in the
///      factory, so the redeploy cannot silently change them. Note that the pinned commit leaves
///      AggregateVerifier at 0.1.0, the same version the live implementation reports, so version
///      alone cannot distinguish the two.
contract DeployCobaltProofImpls is Script {
    /// @notice Game type of the aggregate proof game.
    GameType internal constant AGGREGATE_VERIFIER_GAME_TYPE = GameType.wrap(621);

    // Supplied by the task.
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;
    uint256 internal immutable l2GenesisBlockNumber;
    uint64 internal immutable l2GenesisTimestamp;
    uint64 internal immutable l2BlockTime;
    address internal immutable protocolVersionsProxy;

    // Copied from the live implementation registered for game type 621.
    address internal immutable liveAggregateVerifier;
    IAnchorStateRegistry internal immutable anchorStateRegistry;
    IDelayedWETH internal immutable delayedWeth;
    address internal immutable teeVerifier;
    address internal immutable zkVerifier;
    bytes32 internal immutable configHash;
    uint256 internal immutable l2ChainId;
    uint256 internal immutable blockInterval;
    uint256 internal immutable intermediateBlockInterval;

    string internal addressesJson;

    AggregateVerifier public aggregateVerifier;
    ProtocolVersions public protocolVersionsImpl;

    constructor() {
        // envOr rather than envBytes32 so that the blank placeholders the task ships with
        // surface as the actionable requires in setUp rather than an env parse failure.
        teeImageHash = vm.envOr("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", bytes32(0));
        zkRangeHash = vm.envOr("AGGREGATE_VERIFIER_ZK_RANGE_HASH", bytes32(0));
        zkAggregateHash = vm.envOr("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", bytes32(0));
        l2GenesisBlockNumber = vm.envUint("L2_GENESIS_BLOCK_NUMBER");
        l2GenesisTimestamp = uint64(vm.envUint("L2_GENESIS_TIMESTAMP"));
        l2BlockTime = uint64(vm.envUint("L2_BLOCK_TIME"));

        addressesJson = vm.envString("ADDRESSES_JSON");
        protocolVersionsProxy = vm.parseJsonAddress(vm.readFile(addressesJson), ".protocolVersionsProxy");

        address factory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        liveAggregateVerifier = address(IDisputeGameFactory(factory).gameImpls(AGGREGATE_VERIFIER_GAME_TYPE));

        AggregateVerifier live = AggregateVerifier(liveAggregateVerifier);
        anchorStateRegistry = live.anchorStateRegistry();
        delayedWeth = live.DELAYED_WETH();
        teeVerifier = address(live.TEE_VERIFIER());
        zkVerifier = address(live.ZK_VERIFIER());
        configHash = live.CONFIG_HASH();
        l2ChainId = live.L2_CHAIN_ID();
        blockInterval = live.BLOCK_INTERVAL();
        intermediateBlockInterval = live.INTERMEDIATE_BLOCK_INTERVAL();
    }

    function setUp() public view {
        require(protocolVersionsProxy.code.length != 0, "protocol versions proxy not deployed");
        require(liveAggregateVerifier != address(0), "no aggregate verifier registered for game type 621");
        require(
            GameType.unwrap(AggregateVerifier(liveAggregateVerifier).gameType())
                == GameType.unwrap(AGGREGATE_VERIFIER_GAME_TYPE),
            "live aggregate verifier game type mismatch"
        );

        // Left blank in the task config until the proof programs are released.
        require(teeImageHash != bytes32(0), "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
        require(zkRangeHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
        require(zkAggregateHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");
    }

    function run() external {
        vm.startBroadcast();

        protocolVersionsImpl = new ProtocolVersions();
        aggregateVerifier = new AggregateVerifier({
            gameType_: AGGREGATE_VERIFIER_GAME_TYPE,
            anchorStateRegistry_: anchorStateRegistry,
            delayedWETH: delayedWeth,
            teeVerifier: IVerifier(teeVerifier),
            zkVerifier: IVerifier(zkVerifier),
            teeImageHash: teeImageHash,
            zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash}),
            configHash: configHash,
            l2ChainId: l2ChainId,
            blockInterval: blockInterval,
            intermediateBlockInterval: intermediateBlockInterval,
            scheduleConfig: AggregateVerifier.ScheduleConfig({
                protocolVersions: IProtocolVersions(protocolVersionsProxy),
                genesisBlockNumber: l2GenesisBlockNumber,
                genesisTimestamp: l2GenesisTimestamp,
                blockTime: l2BlockTime
            })
        });

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(address(protocolVersionsImpl).code.length != 0, "protocol versions implementation not deployed");
        require(address(aggregateVerifier).code.length != 0, "aggregate verifier not deployed");

        require(
            keccak256(bytes(protocolVersionsImpl.version())) == keccak256(bytes("1.0.0")),
            "protocol versions version mismatch"
        );
        require(protocolVersionsImpl.initVersion() == 1, "protocol versions init version mismatch");

        require(
            keccak256(bytes(aggregateVerifier.version())) == keccak256(bytes("0.1.0")),
            "aggregate verifier version mismatch"
        );
        require(address(aggregateVerifier) != liveAggregateVerifier, "aggregate verifier was not redeployed");
        require(
            address(aggregateVerifier.PROTOCOL_VERSIONS()) == protocolVersionsProxy,
            "aggregate verifier protocol versions mismatch"
        );

        // The new proof program hashes.
        require(aggregateVerifier.TEE_IMAGE_HASH() == teeImageHash, "aggregate verifier tee image hash mismatch");
        require(aggregateVerifier.ZK_RANGE_HASH() == zkRangeHash, "aggregate verifier zk range hash mismatch");
        require(
            aggregateVerifier.ZK_AGGREGATE_HASH() == zkAggregateHash, "aggregate verifier zk aggregate hash mismatch"
        );

        // Everything carried over from the live implementation.
        require(
            address(aggregateVerifier.anchorStateRegistry()) == address(anchorStateRegistry),
            "aggregate verifier anchor state registry mismatch"
        );
        require(
            address(aggregateVerifier.DELAYED_WETH()) == address(delayedWeth),
            "aggregate verifier delayed weth mismatch"
        );
        require(address(aggregateVerifier.TEE_VERIFIER()) == teeVerifier, "aggregate verifier tee verifier mismatch");
        require(address(aggregateVerifier.ZK_VERIFIER()) == zkVerifier, "aggregate verifier zk verifier mismatch");
        require(aggregateVerifier.CONFIG_HASH() == configHash, "aggregate verifier config hash mismatch");
        require(aggregateVerifier.L2_CHAIN_ID() == l2ChainId, "aggregate verifier l2 chain id mismatch");
        require(aggregateVerifier.BLOCK_INTERVAL() == blockInterval, "aggregate verifier block interval mismatch");
        require(
            aggregateVerifier.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockInterval,
            "aggregate verifier intermediate block interval mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("ProtocolVersions impl:   ", address(protocolVersionsImpl));
        console.log("AggregateVerifier:       ", address(aggregateVerifier));

        vm.writeJson(vm.toString(address(protocolVersionsImpl)), addressesJson, ".protocolVersionsImpl");
        vm.writeJson(vm.toString(address(aggregateVerifier)), addressesJson, ".aggregateVerifier");

        // Recorded so `make verify-proofs` does not have to rebuild the encoding from
        // values the script read off chain.
        vm.writeJson(
            vm.toString(
                abi.encode(
                    AGGREGATE_VERIFIER_GAME_TYPE,
                    anchorStateRegistry,
                    delayedWeth,
                    teeVerifier,
                    zkVerifier,
                    teeImageHash,
                    AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash}),
                    configHash,
                    l2ChainId,
                    blockInterval,
                    intermediateBlockInterval,
                    AggregateVerifier.ScheduleConfig({
                        protocolVersions: IProtocolVersions(protocolVersionsProxy),
                        genesisBlockNumber: l2GenesisBlockNumber,
                        genesisTimestamp: l2GenesisTimestamp,
                        blockTime: l2BlockTime
                    })
                )
            ),
            addressesJson,
            ".aggregateVerifierConstructorArgs"
        );
    }
}
