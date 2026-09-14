// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";
import {ProtocolVersions} from "@base-contracts/src/L1/ProtocolVersions.sol";

/// @notice Deploys the Cobalt implementations that base/contracts compiles at 999999 optimizer runs.
/// @dev AggregateVerifier binds PROTOCOL_VERSIONS as a constructor immutable, so it must be
///      redeployed for the registry to take effect and the proxy from DeployCobaltCoreImpls must
///      already exist. Every other constructor argument is carried over unchanged from the live
///      implementation so this redeploy introduces no behavioural change beyond the binding and the
///      split slow/fast cadence intervals.
contract DeployCobaltProofImpls is Script {
    /// @notice Game type of the aggregate proof game.
    GameType internal constant AGGREGATE_VERIFIER_GAME_TYPE = GameType.wrap(621);

    address internal immutable anchorStateRegistryProxy;
    address internal immutable delayedWeth;
    address internal immutable teeVerifier;
    address internal immutable zkVerifier;
    bytes32 internal immutable configHash;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;
    uint256 internal immutable l2ChainId;
    uint256 internal immutable slowBlockInterval;
    uint256 internal immutable slowIntermediateBlockInterval;
    uint256 internal immutable fastBlockInterval;
    uint256 internal immutable fastIntermediateBlockInterval;
    uint256 internal immutable l2GenesisBlockNumber;
    uint64 internal immutable l2GenesisTimestamp;
    uint64 internal immutable l2BlockTime;
    address internal immutable protocolVersionsProxy;
    string internal addressesJson;

    AggregateVerifier public aggregateVerifier;
    ProtocolVersions public protocolVersionsImpl;

    constructor() {
        anchorStateRegistryProxy = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        delayedWeth = vm.envAddress("MULTIPROOF_DELAYED_WETH_PROXY");
        teeVerifier = vm.envAddress("TEE_VERIFIER");
        zkVerifier = vm.envAddress("ZK_VERIFIER");
        configHash = vm.envBytes32("AGGREGATE_VERIFIER_CONFIG_HASH");
        teeImageHash = vm.envBytes32("AGGREGATE_VERIFIER_TEE_IMAGE_HASH");
        zkRangeHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_RANGE_HASH");
        zkAggregateHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH");
        l2ChainId = vm.envUint("L2_CHAIN_ID");
        slowBlockInterval = vm.envUint("AGGREGATE_VERIFIER_SLOW_BLOCK_INTERVAL");
        slowIntermediateBlockInterval = vm.envUint("AGGREGATE_VERIFIER_SLOW_INTERMEDIATE_BLOCK_INTERVAL");
        fastBlockInterval = vm.envUint("AGGREGATE_VERIFIER_FAST_BLOCK_INTERVAL");
        fastIntermediateBlockInterval = vm.envUint("AGGREGATE_VERIFIER_FAST_INTERMEDIATE_BLOCK_INTERVAL");
        l2GenesisBlockNumber = vm.envUint("L2_GENESIS_BLOCK_NUMBER");
        l2GenesisTimestamp = uint64(vm.envUint("L2_GENESIS_TIMESTAMP"));
        l2BlockTime = uint64(vm.envUint("L2_BLOCK_TIME"));
        addressesJson = vm.envString("ADDRESSES_JSON");
        protocolVersionsProxy = vm.parseJsonAddress(vm.readFile(addressesJson), ".protocolVersionsProxy");
    }

    function setUp() public view {
        require(protocolVersionsProxy.code.length != 0, "protocol versions proxy not deployed");
        require(anchorStateRegistryProxy.code.length != 0, "anchor state registry not deployed");
        require(delayedWeth.code.length != 0, "delayed weth not deployed");
        require(teeVerifier.code.length != 0, "tee verifier not deployed");
        require(zkVerifier.code.length != 0, "zk verifier not deployed");
    }

    function run() external {
        vm.startBroadcast();

        protocolVersionsImpl = new ProtocolVersions();
        aggregateVerifier = new AggregateVerifier({
            gameType_: AGGREGATE_VERIFIER_GAME_TYPE,
            anchorStateRegistry_: IAnchorStateRegistry(anchorStateRegistryProxy),
            delayedWETH: IDelayedWETH(payable(delayedWeth)),
            teeVerifier: IVerifier(teeVerifier),
            zkVerifier: IVerifier(zkVerifier),
            teeImageHash: teeImageHash,
            zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash}),
            configHash: configHash,
            l2ChainId: l2ChainId,
            intervalConfig: AggregateVerifier.IntervalConfig({
                slowBlockInterval: slowBlockInterval,
                slowIntermediateBlockInterval: slowIntermediateBlockInterval,
                fastBlockInterval: fastBlockInterval,
                fastIntermediateBlockInterval: fastIntermediateBlockInterval
            }),
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
            keccak256(bytes(aggregateVerifier.version())) == keccak256(bytes("0.2.0")),
            "aggregate verifier version mismatch"
        );
        require(
            address(aggregateVerifier.PROTOCOL_VERSIONS()) == protocolVersionsProxy,
            "aggregate verifier protocol versions mismatch"
        );
        require(address(aggregateVerifier.TEE_VERIFIER()) == teeVerifier, "aggregate verifier tee verifier mismatch");
        require(address(aggregateVerifier.ZK_VERIFIER()) == zkVerifier, "aggregate verifier zk verifier mismatch");
        require(address(aggregateVerifier.DELAYED_WETH()) == delayedWeth, "aggregate verifier delayed weth mismatch");
        require(aggregateVerifier.CONFIG_HASH() == configHash, "aggregate verifier config hash mismatch");
        require(aggregateVerifier.TEE_IMAGE_HASH() == teeImageHash, "aggregate verifier tee image hash mismatch");
        require(aggregateVerifier.ZK_RANGE_HASH() == zkRangeHash, "aggregate verifier zk range hash mismatch");
        require(
            aggregateVerifier.ZK_AGGREGATE_HASH() == zkAggregateHash, "aggregate verifier zk aggregate hash mismatch"
        );
        require(aggregateVerifier.L2_CHAIN_ID() == l2ChainId, "aggregate verifier l2 chain id mismatch");
    }

    function _writeAddresses() internal {
        console.log("ProtocolVersions impl:   ", address(protocolVersionsImpl));
        console.log("AggregateVerifier:       ", address(aggregateVerifier));

        vm.writeJson(vm.toString(address(protocolVersionsImpl)), addressesJson, ".protocolVersionsImpl");
        vm.writeJson(vm.toString(address(aggregateVerifier)), addressesJson, ".aggregateVerifier");
    }
}
