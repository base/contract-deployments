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

contract DeployCobaltAggregateVerifier is Script {
    GameType internal constant GAME_TYPE = GameType.wrap(621);

    address internal immutable disputeGameFactory;
    address internal immutable expectedCurrentAggregateVerifier;
    bytes32 internal immutable newTeeImageHash;
    bytes32 internal immutable newZkRangeHash;
    bytes32 internal immutable newZkAggregateHash;

    GameType internal immutable currentGameType;
    IAnchorStateRegistry internal immutable currentAnchorStateRegistry;
    IDelayedWETH internal immutable currentDelayedWeth;
    address internal immutable currentTeeVerifier;
    address internal immutable currentZkVerifier;
    bytes32 internal immutable currentConfigHash;
    uint256 internal immutable currentL2ChainId;
    uint256 internal immutable currentBlockInterval;
    uint256 internal immutable currentIntermediateBlockInterval;
    IProtocolVersions internal immutable currentProtocolVersions;
    uint256 internal immutable currentL2GenesisBlockNumber;
    uint64 internal immutable currentL2GenesisTimestamp;
    uint64 internal immutable currentL2BlockTime;

    string internal addressesJson;

    AggregateVerifier public aggregateVerifier;

    constructor() {
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        expectedCurrentAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");
        newTeeImageHash = vm.envOr("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", bytes32(0));
        newZkRangeHash = vm.envOr("AGGREGATE_VERIFIER_ZK_RANGE_HASH", bytes32(0));
        newZkAggregateHash = vm.envOr("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", bytes32(0));
        addressesJson = vm.envString("ADDRESSES_JSON");

        AggregateVerifier current = AggregateVerifier(expectedCurrentAggregateVerifier);
        currentGameType = current.gameType();
        currentAnchorStateRegistry = current.anchorStateRegistry();
        currentDelayedWeth = current.DELAYED_WETH();
        currentTeeVerifier = address(current.TEE_VERIFIER());
        currentZkVerifier = address(current.ZK_VERIFIER());
        currentConfigHash = current.CONFIG_HASH();
        currentL2ChainId = current.L2_CHAIN_ID();
        currentBlockInterval = current.BLOCK_INTERVAL();
        currentIntermediateBlockInterval = current.INTERMEDIATE_BLOCK_INTERVAL();
        currentProtocolVersions = current.PROTOCOL_VERSIONS();
        currentL2GenesisBlockNumber = current.L2_GENESIS_BLOCK_NUMBER();
        currentL2GenesisTimestamp = current.L2_GENESIS_TIMESTAMP();
        currentL2BlockTime = current.L2_BLOCK_TIME();
    }

    function setUp() public view {
        require(
            address(IDisputeGameFactory(disputeGameFactory).gameImpls(GAME_TYPE)) == expectedCurrentAggregateVerifier,
            "current aggregate verifier mismatch"
        );
        require(newTeeImageHash != bytes32(0), "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
        require(newZkRangeHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
        require(newZkAggregateHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");

        require(
            newTeeImageHash != AggregateVerifier(expectedCurrentAggregateVerifier).TEE_IMAGE_HASH()
                || newZkRangeHash != AggregateVerifier(expectedCurrentAggregateVerifier).ZK_RANGE_HASH()
                || newZkAggregateHash != AggregateVerifier(expectedCurrentAggregateVerifier).ZK_AGGREGATE_HASH(),
            "all hashes match current verifier"
        );
    }

    function run() external {
        vm.startBroadcast();
        aggregateVerifier = new AggregateVerifier({
            gameType_: currentGameType,
            anchorStateRegistry_: currentAnchorStateRegistry,
            delayedWETH: currentDelayedWeth,
            teeVerifier: IVerifier(currentTeeVerifier),
            zkVerifier: IVerifier(currentZkVerifier),
            teeImageHash: newTeeImageHash,
            zkHashes: AggregateVerifier.ZkHashes({rangeHash: newZkRangeHash, aggregateHash: newZkAggregateHash}),
            configHash: currentConfigHash,
            l2ChainId: currentL2ChainId,
            blockInterval: currentBlockInterval,
            intermediateBlockInterval: currentIntermediateBlockInterval,
            scheduleConfig: AggregateVerifier.ScheduleConfig({
                protocolVersions: currentProtocolVersions,
                genesisBlockNumber: currentL2GenesisBlockNumber,
                genesisTimestamp: currentL2GenesisTimestamp,
                blockTime: currentL2BlockTime
            })
        });
        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(address(aggregateVerifier).code.length != 0, "aggregate verifier not deployed");
        require(address(aggregateVerifier) != expectedCurrentAggregateVerifier, "aggregate verifier not replaced");
        require(
            keccak256(bytes(aggregateVerifier.version())) == keccak256(bytes("0.2.0")),
            "aggregate verifier version mismatch"
        );
        require(aggregateVerifier.TEE_IMAGE_HASH() == newTeeImageHash, "tee image hash mismatch");
        require(aggregateVerifier.ZK_RANGE_HASH() == newZkRangeHash, "zk range hash mismatch");
        require(aggregateVerifier.ZK_AGGREGATE_HASH() == newZkAggregateHash, "zk aggregate hash mismatch");
        _assertImmutableContinuity(aggregateVerifier);
    }

    function _assertImmutableContinuity(AggregateVerifier next) internal view {
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(currentGameType), "game type changed");
        require(address(next.anchorStateRegistry()) == address(currentAnchorStateRegistry), "asr changed");
        require(address(next.DELAYED_WETH()) == address(currentDelayedWeth), "delayed weth changed");
        require(address(next.TEE_VERIFIER()) == currentTeeVerifier, "tee verifier changed");
        require(address(next.ZK_VERIFIER()) == currentZkVerifier, "zk verifier changed");
        require(next.CONFIG_HASH() == currentConfigHash, "config hash changed");
        require(next.L2_CHAIN_ID() == currentL2ChainId, "l2 chain id changed");
        require(next.BLOCK_INTERVAL() == currentBlockInterval, "block interval changed");
        require(
            next.INTERMEDIATE_BLOCK_INTERVAL() == currentIntermediateBlockInterval,
            "intermediate block interval changed"
        );
        require(address(next.PROTOCOL_VERSIONS()) == address(currentProtocolVersions), "registry changed");
        require(next.L2_GENESIS_BLOCK_NUMBER() == currentL2GenesisBlockNumber, "genesis block changed");
        require(next.L2_GENESIS_TIMESTAMP() == currentL2GenesisTimestamp, "genesis timestamp changed");
        require(next.L2_BLOCK_TIME() == currentL2BlockTime, "l2 block time changed");
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", address(aggregateVerifier));
        vm.writeJson(vm.toString(address(aggregateVerifier)), addressesJson, ".aggregateVerifier");
        vm.writeJson(
            vm.toString(
                abi.encode(
                    currentGameType,
                    currentAnchorStateRegistry,
                    currentDelayedWeth,
                    IVerifier(currentTeeVerifier),
                    IVerifier(currentZkVerifier),
                    newTeeImageHash,
                    AggregateVerifier.ZkHashes({rangeHash: newZkRangeHash, aggregateHash: newZkAggregateHash}),
                    currentConfigHash,
                    currentL2ChainId,
                    currentBlockInterval,
                    currentIntermediateBlockInterval,
                    AggregateVerifier.ScheduleConfig({
                        protocolVersions: currentProtocolVersions,
                        genesisBlockNumber: currentL2GenesisBlockNumber,
                        genesisTimestamp: currentL2GenesisTimestamp,
                        blockTime: currentL2BlockTime
                    })
                )
            ),
            addressesJson,
            ".aggregateVerifierConstructorArgs"
        );
    }
}
