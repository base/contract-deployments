// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

/// @notice Redeploys AggregateVerifier with updated TEE_IMAGE_HASH, ZK_RANGE_HASH,
/// and ZK_AGGREGATE_HASH. All other immutables are read from the current
/// onchain AggregateVerifier to guarantee continuity.
contract DeployAggregateVerifier is Script {
    // Task config from .env.
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal immutable currentAggregateVerifier;

    // Constructor args copied from the live AggregateVerifier.
    GameType internal immutable currentGameType;
    IAnchorStateRegistry internal immutable currentAnchorStateRegistry;
    IDelayedWETH internal immutable currentDelayedWeth;
    address internal immutable currentTeeVerifier;
    address internal immutable currentZkVerifier;
    bytes32 internal immutable currentConfigHash;
    uint256 internal immutable currentL2ChainId;
    uint256 internal immutable currentBlockInterval;
    uint256 internal immutable currentIntermediateBlockInterval;

    // Deployment output written to addresses.json.
    address public aggregateVerifier;

    constructor() {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        currentGameType = currentAggregate.gameType();
        currentAnchorStateRegistry = currentAggregate.anchorStateRegistry();
        currentDelayedWeth = currentAggregate.DELAYED_WETH();
        currentTeeVerifier = address(currentAggregate.TEE_VERIFIER());
        currentZkVerifier = address(currentAggregate.ZK_VERIFIER());
        currentConfigHash = currentAggregate.CONFIG_HASH();
        currentL2ChainId = currentAggregate.L2_CHAIN_ID();
        currentBlockInterval = currentAggregate.BLOCK_INTERVAL();
        currentIntermediateBlockInterval = currentAggregate.INTERMEDIATE_BLOCK_INTERVAL();
    }

    function setUp() public view {
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(GameType.unwrap(currentGameType) == GameType.unwrap(gameTypeEnv), "current game type mismatch");
        require(currentTeeVerifier != address(0), "current tee verifier not found");
        require(currentZkVerifier != address(0), "current zk verifier not found");
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            teeImageHashEnv != currentAggregate.TEE_IMAGE_HASH() || zkRangeHashEnv != currentAggregate.ZK_RANGE_HASH()
                || zkAggregateHashEnv != currentAggregate.ZK_AGGREGATE_HASH(),
            "all hashes are identical to the current aggregate verifier"
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
                teeImageHash: teeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: currentConfigHash,
                l2ChainId: currentL2ChainId,
                blockInterval: currentBlockInterval,
                intermediateBlockInterval: currentIntermediateBlockInterval
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(currentGameType), "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == address(currentAnchorStateRegistry), "aggregate asr mismatch");
        require(
            address(av.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "aggregate dgf mismatch"
        );
        require(address(av.DELAYED_WETH()) == address(currentDelayedWeth), "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == currentTeeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == currentZkVerifier, "aggregate zk verifier mismatch");
        require(av.CONFIG_HASH() == currentConfigHash, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == currentL2ChainId, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == currentBlockInterval, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == currentIntermediateBlockInterval,
            "aggregate intermediate interval mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "aggregateVerifier", value: aggregateVerifier});
        string memory path = vm.envOr("ADDRESSES_JSON", string("addresses.json"));
        vm.writeJson({json: json, path: path});
    }
}
