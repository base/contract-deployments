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

import {IAggregateVerifierV020} from "./IAggregateVerifierV020.sol";

/// @notice Deploys AggregateVerifier 0.3.0 for Denim. It carries the live slow-block intervals plus the
///         post-Denim fast-block intervals, and new proof program hashes. Every other constructor
///         argument is copied from the live 0.2.0 verifier registered in the DisputeGameFactory.
contract DeployDenimProofImpls is Script {
    string internal constant OLD_VERSION = "0.2.0";
    string internal constant NEW_VERSION = "0.3.0";

    // Task config from .env.
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable oldAggregateVerifier;
    uint256 internal immutable fastBlockInterval;
    uint256 internal immutable fastIntermediateBlockInterval;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;

    // Constructor args copied from the live AggregateVerifier.
    IAnchorStateRegistry internal immutable anchorStateRegistry;
    IDelayedWETH internal immutable delayedWeth;
    IVerifier internal immutable teeVerifier;
    IVerifier internal immutable zkVerifier;
    bytes32 internal immutable configHash;
    uint256 internal immutable l2ChainId;
    uint256 internal immutable slowBlockInterval;
    uint256 internal immutable slowIntermediateBlockInterval;
    IProtocolVersions internal immutable protocolVersions;
    uint256 internal immutable l2GenesisBlockNumber;
    uint64 internal immutable l2GenesisTimestamp;
    uint64 internal immutable l2BlockTime;

    // Deployment output written to addresses.json.
    address public aggregateVerifier;

    constructor() {
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameType = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        oldAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");
        fastBlockInterval = vm.envUint("FAST_BLOCK_INTERVAL");
        fastIntermediateBlockInterval = vm.envUint("FAST_INTERMEDIATE_BLOCK_INTERVAL");
        teeImageHash = vm.envOr("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", bytes32(0));
        zkRangeHash = vm.envOr("AGGREGATE_VERIFIER_ZK_RANGE_HASH", bytes32(0));
        zkAggregateHash = vm.envOr("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", bytes32(0));

        IAggregateVerifierV020 live = IAggregateVerifierV020(oldAggregateVerifier);
        anchorStateRegistry = IAnchorStateRegistry(live.anchorStateRegistry());
        delayedWeth = IDelayedWETH(payable(live.DELAYED_WETH()));
        teeVerifier = IVerifier(live.TEE_VERIFIER());
        zkVerifier = IVerifier(live.ZK_VERIFIER());
        configHash = live.CONFIG_HASH();
        l2ChainId = live.L2_CHAIN_ID();
        slowBlockInterval = live.BLOCK_INTERVAL();
        slowIntermediateBlockInterval = live.INTERMEDIATE_BLOCK_INTERVAL();
        protocolVersions = IProtocolVersions(live.PROTOCOL_VERSIONS());
        l2GenesisBlockNumber = live.L2_GENESIS_BLOCK_NUMBER();
        l2GenesisTimestamp = live.L2_GENESIS_TIMESTAMP();
        l2BlockTime = live.L2_BLOCK_TIME();
    }

    function setUp() public view {
        require(
            address(IDisputeGameFactory(disputeGameFactory).gameImpls(gameType)) == oldAggregateVerifier,
            "unexpected current aggregate verifier"
        );

        IAggregateVerifierV020 live = IAggregateVerifierV020(oldAggregateVerifier);
        require(_eq(live.version(), OLD_VERSION), "unexpected current aggregate verifier version");
        require(GameType.unwrap(live.gameType()) == GameType.unwrap(gameType), "current game type mismatch");

        require(teeImageHash != bytes32(0), "AGGREGATE_VERIFIER_TEE_IMAGE_HASH not set");
        require(zkRangeHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_RANGE_HASH not set");
        require(zkAggregateHash != bytes32(0), "AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH not set");
        require(
            fastBlockInterval / fastIntermediateBlockInterval == slowBlockInterval / slowIntermediateBlockInterval,
            "intermediate root count mismatch"
        );
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: gameType,
                anchorStateRegistry_: anchorStateRegistry,
                delayedWETH: delayedWeth,
                teeVerifier: teeVerifier,
                zkVerifier: zkVerifier,
                teeImageHash: teeImageHash,
                zkHashes: _zkHashes(),
                configHash: configHash,
                l2ChainId: l2ChainId,
                intervalConfig: _intervalConfig(),
                scheduleConfig: _scheduleConfig()
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        IAggregateVerifierV020 live = IAggregateVerifierV020(oldAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(_eq(av.version(), NEW_VERSION), "new aggregate verifier version mismatch");

        require(av.TEE_IMAGE_HASH() == teeImageHash, "tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "zk aggregate hash mismatch");

        require(av.SLOW_BLOCK_INTERVAL() == slowBlockInterval, "slow block interval mismatch");
        require(
            av.SLOW_INTERMEDIATE_BLOCK_INTERVAL() == slowIntermediateBlockInterval,
            "slow intermediate block interval mismatch"
        );
        require(av.FAST_BLOCK_INTERVAL() == fastBlockInterval, "fast block interval mismatch");
        require(
            av.FAST_INTERMEDIATE_BLOCK_INTERVAL() == fastIntermediateBlockInterval,
            "fast intermediate block interval mismatch"
        );

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(gameType), "game type mismatch");
        require(address(av.anchorStateRegistry()) == address(anchorStateRegistry), "asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == live.DISPUTE_GAME_FACTORY(), "dgf mismatch");
        require(address(av.DELAYED_WETH()) == address(delayedWeth), "delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == address(teeVerifier), "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == address(zkVerifier), "zk verifier mismatch");
        require(av.CONFIG_HASH() == configHash, "config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainId, "l2 chain id mismatch");
        require(address(av.PROTOCOL_VERSIONS()) == address(protocolVersions), "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == l2GenesisBlockNumber, "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == l2GenesisTimestamp, "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == l2BlockTime, "l2 block time mismatch");
        require(
            av.intermediateOutputRootsCount() == slowBlockInterval / slowIntermediateBlockInterval,
            "intermediate root count changed"
        );
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory json =
            vm.serializeAddress({objectKey: "root", valueKey: "aggregateVerifier", value: aggregateVerifier});
        string memory path = vm.envString("ADDRESSES_JSON");
        vm.writeJson({json: json, path: path});
        vm.writeJson(
            vm.toString(
                abi.encode(
                    gameType,
                    anchorStateRegistry,
                    delayedWeth,
                    teeVerifier,
                    zkVerifier,
                    teeImageHash,
                    _zkHashes(),
                    configHash,
                    l2ChainId,
                    _intervalConfig(),
                    _scheduleConfig()
                )
            ),
            path,
            ".aggregateVerifierConstructorArgs"
        );
    }

    function _zkHashes() internal view returns (AggregateVerifier.ZkHashes memory) {
        return AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash});
    }

    function _intervalConfig() internal view returns (AggregateVerifier.IntervalConfig memory) {
        return AggregateVerifier.IntervalConfig({
            slowBlockInterval: slowBlockInterval,
            slowIntermediateBlockInterval: slowIntermediateBlockInterval,
            fastBlockInterval: fastBlockInterval,
            fastIntermediateBlockInterval: fastIntermediateBlockInterval
        });
    }

    function _scheduleConfig() internal view returns (AggregateVerifier.ScheduleConfig memory) {
        return AggregateVerifier.ScheduleConfig({
            protocolVersions: protocolVersions,
            genesisBlockNumber: l2GenesisBlockNumber,
            genesisTimestamp: l2GenesisTimestamp,
            blockTime: l2BlockTime
        });
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
