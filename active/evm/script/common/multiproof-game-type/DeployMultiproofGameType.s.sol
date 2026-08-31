// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/L1/proofs/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/L1/proofs/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/L1/proofs/IVerifier.sol";
import {ISP1Verifier} from "interfaces/L1/proofs/zk/ISP1Verifier.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {TEEProverRegistry} from "@base-contracts/src/L1/proofs/tee/TEEProverRegistry.sol";
import {TEEVerifier} from "@base-contracts/src/L1/proofs/tee/TEEVerifier.sol";
import {ZKVerifier} from "@base-contracts/src/L1/proofs/zk/ZKVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

import {MultiproofGameTypeChecks} from "./MultiproofGameTypeChecks.sol";

interface IDisputeGameFactoryAdmin {
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
    function setInitBond(GameType gameType, uint256 initBond) external;
}

/// @notice Deploys fresh TEE, ZK, and aggregate verifiers for a new multiproof game type.
/// Existing chain-level immutable values are copied from the current AggregateVerifier.
contract DeployMultiproofGameType is Script {
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable currentGameTypeEnv;
    GameType internal immutable newGameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;
    uint256 internal immutable blockIntervalEnv;
    uint256 internal immutable intermediateBlockIntervalEnv;
    uint256 internal immutable initBondEnv;
    IProtocolVersions internal immutable protocolVersionsEnv;
    uint256 internal immutable l2GenesisBlockNumberEnv;
    uint64 internal immutable l2GenesisTimestampEnv;
    uint64 internal immutable l2BlockTimeEnv;
    uint64 internal immutable denimActivationTimestampEnv;

    address internal immutable currentAggregateVerifier;
    IAnchorStateRegistry internal immutable currentAnchorStateRegistry;
    IDelayedWETH internal immutable currentDelayedWeth;
    TEEProverRegistry internal immutable currentTeeProverRegistry;
    ISP1Verifier internal immutable currentSp1Verifier;
    bytes32 internal immutable currentConfigHash;
    uint256 internal immutable currentL2ChainId;

    address public teeVerifier;
    address public zkVerifier;
    address public aggregateVerifier;

    constructor() {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        uint256 currentGameType = vm.envUint("CURRENT_GAME_TYPE");
        uint256 newGameType = vm.envUint("NEW_GAME_TYPE");
        require(currentGameType <= type(uint32).max && newGameType <= type(uint32).max, "game type overflow");
        currentGameTypeEnv = GameType.wrap(uint32(currentGameType));
        newGameTypeEnv = GameType.wrap(uint32(newGameType));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");
        initBondEnv = vm.envUint("INIT_BOND");
        protocolVersionsEnv = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS"));
        l2GenesisBlockNumberEnv = vm.envUint("L2_GENESIS_BLOCK_NUMBER");
        uint256 l2GenesisTimestamp = vm.envUint("L2_GENESIS_TIMESTAMP");
        uint256 l2BlockTime = vm.envUint("L2_BLOCK_TIME");
        uint256 denimActivationTimestamp = vm.envUint("DENIM_ACTIVATION_TIMESTAMP");
        require(
            l2GenesisTimestamp <= type(uint64).max && l2BlockTime <= type(uint64).max
                && denimActivationTimestamp <= type(uint64).max,
            "l2 time overflow"
        );
        require(denimActivationTimestamp != 0, "denim activation not set");
        l2GenesisTimestampEnv = uint64(l2GenesisTimestamp);
        l2BlockTimeEnv = uint64(l2BlockTime);
        denimActivationTimestampEnv = uint64(denimActivationTimestamp);

        IDisputeGameFactory factory = IDisputeGameFactory(disputeGameFactoryProxyEnv);
        currentAggregateVerifier = address(factory.gameImpls(currentGameTypeEnv));
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        currentAnchorStateRegistry = current.anchorStateRegistry();
        currentDelayedWeth = current.DELAYED_WETH();
        currentTeeProverRegistry = TEEVerifier(address(current.TEE_VERIFIER())).TEE_PROVER_REGISTRY();
        currentSp1Verifier = ZKVerifier(address(current.ZK_VERIFIER())).SP1_VERIFIER();
        currentConfigHash = current.CONFIG_HASH();
        currentL2ChainId = current.L2_CHAIN_ID();
    }

    function setUp() public view {
        IDisputeGameFactory factory = IDisputeGameFactory(disputeGameFactoryProxyEnv);
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(
            GameType.unwrap(AggregateVerifier(currentAggregateVerifier).gameType())
                == GameType.unwrap(currentGameTypeEnv),
            "current game type mismatch"
        );
        require(GameType.unwrap(newGameTypeEnv) != GameType.unwrap(currentGameTypeEnv), "new game type is current");
        require(address(factory.gameImpls(newGameTypeEnv)) == address(0), "new game type already registered");
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");
        require(address(protocolVersionsEnv) != address(0), "protocol versions not set");
        require(l2BlockTimeEnv == 2, "l2 block time must be two seconds");
        require(blockIntervalEnv == 6000, "block interval must be 6000");
        require(intermediateBlockIntervalEnv == 300, "intermediate block interval must be 300");

        uint64[] memory schedule = protocolVersionsEnv.getSchedule();
        require(
            schedule.length > MultiproofGameTypeChecks.DENIM_UPGRADE_INDEX
                && schedule[MultiproofGameTypeChecks.DENIM_UPGRADE_INDEX] == denimActivationTimestampEnv,
            "denim activation mismatch"
        );
    }

    function run() external {
        vm.startBroadcast();

        teeVerifier = address(new TEEVerifier(currentTeeProverRegistry, currentAnchorStateRegistry));
        zkVerifier = address(new ZKVerifier(currentSp1Verifier, currentAnchorStateRegistry));
        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: newGameTypeEnv,
                anchorStateRegistry_: currentAnchorStateRegistry,
                delayedWETH: currentDelayedWeth,
                teeVerifier: IVerifier(teeVerifier),
                zkVerifier: IVerifier(zkVerifier),
                teeImageHash: teeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: currentConfigHash,
                l2ChainId: currentL2ChainId,
                blockInterval: blockIntervalEnv,
                intermediateBlockInterval: intermediateBlockIntervalEnv,
                scheduleConfig: AggregateVerifier.ScheduleConfig({
                    protocolVersions: protocolVersionsEnv,
                    genesisBlockNumber: l2GenesisBlockNumberEnv,
                    genesisTimestamp: l2GenesisTimestampEnv,
                    blockTime: l2BlockTimeEnv
                })
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        MultiproofGameTypeChecks.assertDeployment(
            AggregateVerifier(aggregateVerifier),
            AggregateVerifier(currentAggregateVerifier),
            MultiproofGameTypeChecks.Expected({
                gameType: newGameTypeEnv,
                disputeGameFactory: disputeGameFactoryProxyEnv,
                teeVerifier: teeVerifier,
                zkVerifier: zkVerifier,
                teeImageHash: teeImageHashEnv,
                zkRangeHash: zkRangeHashEnv,
                zkAggregateHash: zkAggregateHashEnv,
                protocolVersions: protocolVersionsEnv,
                l2GenesisBlockNumber: l2GenesisBlockNumberEnv,
                l2GenesisTimestamp: l2GenesisTimestampEnv,
                denimActivationTimestamp: denimActivationTimestampEnv
            })
        );
    }

    function _writeAddresses() internal {
        console.log("TEEVerifier:", teeVerifier);
        console.log("ZKVerifier:", zkVerifier);
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory root = "root";
        vm.serializeAddress(root, "teeVerifier", teeVerifier);
        vm.serializeAddress(root, "zkVerifier", zkVerifier);
        vm.serializeAddress(root, "aggregateVerifier", aggregateVerifier);
        vm.serializeBytes(
            root,
            "setImplementationCalldata",
            abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (newGameTypeEnv, aggregateVerifier, bytes("")))
        );
        vm.serializeBytes(
            root,
            "setInitBondCalldata",
            abi.encodeCall(IDisputeGameFactoryAdmin.setInitBond, (newGameTypeEnv, initBondEnv))
        );
        vm.serializeBytes(
            root, "setTEEGameTypeCalldata", abi.encodeCall(TEEProverRegistry.setGameType, (newGameTypeEnv))
        );
        string memory json = vm.serializeBytes(
            root,
            "setRespectedGameTypeCalldata",
            abi.encodeCall(IAnchorStateRegistry.setRespectedGameType, (newGameTypeEnv))
        );
        vm.writeJson(json, vm.envString("ADDRESSES_JSON"));
    }
}
