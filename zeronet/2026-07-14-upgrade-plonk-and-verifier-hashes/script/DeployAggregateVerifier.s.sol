// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

/// @notice Redeploys AggregateVerifier with updated ZK hashes; preserves TEE_IMAGE_HASH and other immutables.
contract DeployAggregateVerifier is Script {
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;

    address internal immutable currentAggregateVerifier;
    GameType internal immutable currentGameType;
    IAnchorStateRegistry internal immutable currentAnchorStateRegistry;
    IDelayedWETH internal immutable currentDelayedWeth;
    address internal immutable currentTeeVerifier;
    address internal immutable currentZkVerifier;
    bytes32 internal immutable currentTeeImageHash;
    bytes32 internal immutable currentConfigHash;
    uint256 internal immutable currentL2ChainId;
    uint256 internal immutable currentBlockInterval;
    uint256 internal immutable currentIntermediateBlockInterval;

    address public aggregateVerifier;

    constructor() {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));

        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        currentGameType = current.gameType();
        currentAnchorStateRegistry = current.anchorStateRegistry();
        currentDelayedWeth = current.DELAYED_WETH();
        currentTeeVerifier = address(current.TEE_VERIFIER());
        currentZkVerifier = address(current.ZK_VERIFIER());
        currentTeeImageHash = current.TEE_IMAGE_HASH();
        currentConfigHash = current.CONFIG_HASH();
        currentL2ChainId = current.L2_CHAIN_ID();
        currentBlockInterval = current.BLOCK_INTERVAL();
        currentIntermediateBlockInterval = current.INTERMEDIATE_BLOCK_INTERVAL();
    }

    function setUp() public view {
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(GameType.unwrap(currentGameType) == GameType.unwrap(gameTypeEnv), "game type mismatch");
        require(zkRangeHashEnv != bytes32(0) && zkAggregateHashEnv != bytes32(0), "zk hashes not set");

        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        require(
            zkRangeHashEnv != current.ZK_RANGE_HASH() || zkAggregateHashEnv != current.ZK_AGGREGATE_HASH(),
            "zk hashes unchanged"
        );
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: currentGameType,
                anchorStateRegistry_: currentAnchorStateRegistry,
                delayedWETH: currentDelayedWeth,
                teeVerifier: IVerifier(currentTeeVerifier),
                zkVerifier: IVerifier(currentZkVerifier),
                teeImageHash: currentTeeImageHash,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: currentConfigHash,
                l2ChainId: currentL2ChainId,
                blockInterval: currentBlockInterval,
                intermediateBlockInterval: currentIntermediateBlockInterval
            })
        );

        vm.stopBroadcast();

        AggregateVerifier av = AggregateVerifier(aggregateVerifier);
        require(av.TEE_IMAGE_HASH() == currentTeeImageHash, "tee hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "zk aggregate hash mismatch");
        require(address(av.TEE_VERIFIER()) == currentTeeVerifier, "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == currentZkVerifier, "zk verifier mismatch");

        console.log("AggregateVerifier:", aggregateVerifier);
        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "aggregateVerifier", value: aggregateVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
