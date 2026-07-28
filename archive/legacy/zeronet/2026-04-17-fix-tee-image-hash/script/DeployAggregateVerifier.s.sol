// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {MockVerifier} from "@base-contracts/src/multiproof/mocks/MockVerifier.sol";

/// @notice Redeploys AggregateVerifier with a corrected TEE_IMAGE_HASH.
/// All other immutables are read on-chain from the existing AggregateVerifier to
/// guarantee continuity.
contract DeployAggregateVerifier is Script {
    address internal existingAggregateVerifierEnv;
    bytes32 internal currentTeeImageHashEnv;
    bytes32 internal newTeeImageHashEnv;

    GameType internal gameType;
    IAnchorStateRegistry internal anchorStateRegistry;
    IDelayedWETH internal delayedWeth;
    address internal teeVerifier;
    address internal zkVerifier;
    bytes32 internal zkRangeHash;
    bytes32 internal zkAggregateHash;
    bytes32 internal configHash;
    uint256 internal l2ChainId;
    uint256 internal blockInterval;
    uint256 internal intermediateBlockInterval;
    uint256 internal proofThreshold;

    address public aggregateVerifier;

    function setUp() public {
        existingAggregateVerifierEnv = vm.envAddress("EXISTING_AGGREGATE_VERIFIER");
        currentTeeImageHashEnv = vm.envBytes32("CURRENT_TEE_IMAGE_HASH");
        newTeeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");

        require(currentTeeImageHashEnv != newTeeImageHashEnv, "tee image hash already target");

        AggregateVerifier existing = AggregateVerifier(existingAggregateVerifierEnv);

        require(existing.TEE_IMAGE_HASH() == currentTeeImageHashEnv, "unexpected current tee image hash");

        gameType = existing.gameType();
        anchorStateRegistry = existing.anchorStateRegistry();
        delayedWeth = existing.DELAYED_WETH();
        teeVerifier = address(existing.TEE_VERIFIER());
        zkVerifier = address(existing.ZK_VERIFIER());
        zkRangeHash = existing.ZK_RANGE_HASH();
        zkAggregateHash = existing.ZK_AGGREGATE_HASH();
        configHash = existing.CONFIG_HASH();
        l2ChainId = existing.L2_CHAIN_ID();
        blockInterval = existing.BLOCK_INTERVAL();
        intermediateBlockInterval = existing.INTERMEDIATE_BLOCK_INTERVAL();
        proofThreshold = existing.PROOF_THRESHOLD();
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: gameType,
                anchorStateRegistry_: anchorStateRegistry,
                delayedWETH: delayedWeth,
                teeVerifier: TEEVerifier(teeVerifier),
                zkVerifier: MockVerifier(zkVerifier),
                teeImageHash: newTeeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash}),
                configHash: configHash,
                l2ChainId: l2ChainId,
                blockInterval: blockInterval,
                intermediateBlockInterval: intermediateBlockInterval,
                proofThreshold: proofThreshold
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(gameType), "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == address(anchorStateRegistry), "aggregate asr mismatch");
        require(
            address(av.DISPUTE_GAME_FACTORY()) == address(anchorStateRegistry.disputeGameFactory()),
            "aggregate dgf mismatch"
        );
        require(address(av.DELAYED_WETH()) == address(delayedWeth), "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == teeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == zkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == newTeeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == configHash, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainId, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == blockInterval, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockInterval, "aggregate intermediate interval mismatch"
        );
        require(av.PROOF_THRESHOLD() == proofThreshold, "aggregate proof threshold mismatch");
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "aggregateVerifier", value: aggregateVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
