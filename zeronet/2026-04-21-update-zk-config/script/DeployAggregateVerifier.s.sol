// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/multiproof/IVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

/// @notice Redeploys AggregateVerifier with a new ZK_VERIFIER and target ZK program hashes.
/// All other immutables are read on-chain from the existing AggregateVerifier to
/// guarantee continuity.
contract DeployAggregateVerifier is Script {
    // Task config from .env.
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal sp1VerifierEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;
    address internal currentZkVerifier;

    // Immutable constructor args copied from the live AggregateVerifier.
    GameType internal currentGameType;
    IAnchorStateRegistry internal currentAnchorStateRegistry;
    IDelayedWETH internal currentDelayedWeth;
    address internal currentTeeVerifier;
    bytes32 internal currentTeeImageHash;
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
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierEnv = vm.envAddress("SP1_VERIFIER");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv),
            "current game type mismatch"
        );

        currentGameType = currentAggregate.gameType();
        currentAnchorStateRegistry = currentAggregate.anchorStateRegistry();
        currentDelayedWeth = currentAggregate.DELAYED_WETH();
        currentTeeVerifier = address(currentAggregate.TEE_VERIFIER());
        currentZkVerifier = address(currentAggregate.ZK_VERIFIER());
        currentTeeImageHash = currentAggregate.TEE_IMAGE_HASH();
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
        require(nextZkVerifier != currentZkVerifier, "next zk verifier equals current");
        require(sp1VerifierEnv != address(0), "sp1 verifier not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY()) == address(currentAnchorStateRegistry),
            "next zk verifier asr mismatch"
        );
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "next zk verifier sp1 mismatch");
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: currentGameType,
                anchorStateRegistry_: currentAnchorStateRegistry,
                delayedWETH: currentDelayedWeth,
                teeVerifier: TEEVerifier(currentTeeVerifier),
                zkVerifier: IVerifier(nextZkVerifier),
                teeImageHash: currentTeeImageHash,
                zkHashes: AggregateVerifier.ZkHashes({
                    rangeHash: zkRangeHashEnv,
                    aggregateHash: zkAggregateHashEnv
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

        require(aggregateVerifier != address(0), "aggregate verifier not deployed");
        require(aggregateVerifier != currentAggregateVerifier, "new aggregate verifier equals current");
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
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");
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
