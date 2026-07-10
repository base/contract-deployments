// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/multiproof/IVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

/// @notice Redeploys AggregateVerifier with a new verifier config.
/// All other immutables are read onchain from the existing AggregateVerifier to
/// guarantee continuity.
contract DeployAggregateVerifier is Script {
    // Task config from .env.
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    GameType internal immutable GAME_TYPE_ENV = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
    address internal immutable SP1_VERIFIER_ENV = vm.envAddress("SP1_VERIFIER");

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;

    // Immutable constructor args copied from the live AggregateVerifier.
    GameType internal currentGameType;
    IAnchorStateRegistry internal currentAnchorStateRegistry;
    IDelayedWETH internal currentDelayedWeth;
    address internal currentTeeVerifier;
    bytes32 internal currentTeeImageHash;
    bytes32 internal currentZkRangeHash;
    bytes32 internal currentZkAggregateHash;
    bytes32 internal currentConfigHash;
    uint256 internal currentL2ChainId;
    uint256 internal currentBlockInterval;
    uint256 internal currentIntermediateBlockInterval;
    uint256 internal currentProofThreshold;

    // Deployment input produced by DeployZkVerifier and read from addresses.json.
    address internal nextZkVerifier;

    // Deployment output written to addresses.json.
    address public aggregateVerifier;

    function setUp() public {
        currentAggregateVerifier = address(IDisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(GAME_TYPE_ENV));
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(GAME_TYPE_ENV), "current game type mismatch"
        );

        currentGameType = currentAggregate.gameType();
        currentAnchorStateRegistry = currentAggregate.anchorStateRegistry();
        currentDelayedWeth = currentAggregate.DELAYED_WETH();
        currentTeeVerifier = address(currentAggregate.TEE_VERIFIER());
        currentTeeImageHash = currentAggregate.TEE_IMAGE_HASH();
        currentZkRangeHash = currentAggregate.ZK_RANGE_HASH();
        currentZkAggregateHash = currentAggregate.ZK_AGGREGATE_HASH();
        currentConfigHash = currentAggregate.CONFIG_HASH();
        currentL2ChainId = currentAggregate.L2_CHAIN_ID();
        currentBlockInterval = currentAggregate.BLOCK_INTERVAL();
        currentIntermediateBlockInterval = currentAggregate.INTERMEDIATE_BLOCK_INTERVAL();
        currentProofThreshold = currentAggregate.PROOF_THRESHOLD();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});

        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY()) == address(currentAnchorStateRegistry),
            "next zk verifier asr mismatch"
        );
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == SP1_VERIFIER_ENV, "next zk verifier sp1 mismatch");
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: currentGameType,
                anchorStateRegistry_: currentAnchorStateRegistry,
                delayedWETH: currentDelayedWeth,
                teeVerifier: IVerifier(currentTeeVerifier),
                zkVerifier: IVerifier(nextZkVerifier),
                teeImageHash: currentTeeImageHash,
                zkHashes: AggregateVerifier.ZkHashes({
                    rangeHash: currentZkRangeHash, aggregateHash: currentZkAggregateHash
                }),
                configHash: currentConfigHash,
                l2ChainId: currentL2ChainId,
                blockInterval: currentBlockInterval,
                intermediateBlockInterval: currentIntermediateBlockInterval,
                proofThreshold: currentProofThreshold
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(currentGameType), "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == address(currentAnchorStateRegistry), "aggregate asr mismatch");
        require(
            address(av.DISPUTE_GAME_FACTORY()) == address(currentAnchorStateRegistry.disputeGameFactory()),
            "aggregate dgf mismatch"
        );
        require(address(av.DELAYED_WETH()) == address(currentDelayedWeth), "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == currentTeeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == nextZkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == currentTeeImageHash, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == currentZkRangeHash, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == currentZkAggregateHash, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == currentConfigHash, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == currentL2ChainId, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == currentBlockInterval, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == currentIntermediateBlockInterval,
            "aggregate intermediate interval mismatch"
        );
        require(av.PROOF_THRESHOLD() == currentProofThreshold, "aggregate proof threshold mismatch");
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);
        vm.writeJson({json: vm.toString(aggregateVerifier), path: "addresses.json", valueKey: ".aggregateVerifier"});
    }
}
