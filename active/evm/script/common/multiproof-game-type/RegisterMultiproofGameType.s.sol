// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

import {MultiproofGameTypeChecks} from "./MultiproofGameTypeChecks.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function initBonds(GameType gameType) external view returns (uint256);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
    function setInitBond(GameType gameType, uint256 initBond) external;
}

/// @notice Registers a deployed AggregateVerifier and its initialization bond under a new game type.
contract RegisterMultiproofGameType is MultisigScript {
    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable newGameTypeEnv;
    uint256 internal immutable initBondEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;
    IProtocolVersions internal immutable protocolVersionsEnv;
    uint256 internal immutable l2GenesisBlockNumberEnv;
    uint64 internal immutable l2GenesisTimestampEnv;
    uint64 internal immutable denimActivationTimestampEnv;

    address internal immutable currentAggregateVerifier;
    address internal immutable aggregateVerifier;
    address internal immutable teeVerifier;
    address internal immutable zkVerifier;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        uint256 currentGameType = vm.envUint("CURRENT_GAME_TYPE");
        uint256 newGameType = vm.envUint("NEW_GAME_TYPE");
        require(currentGameType <= type(uint32).max && newGameType <= type(uint32).max, "game type overflow");
        newGameTypeEnv = GameType.wrap(uint32(newGameType));
        initBondEnv = vm.envUint("INIT_BOND");
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        protocolVersionsEnv = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS"));
        l2GenesisBlockNumberEnv = vm.envUint("L2_GENESIS_BLOCK_NUMBER");
        uint256 l2GenesisTimestamp = vm.envUint("L2_GENESIS_TIMESTAMP");
        uint256 denimActivationTimestamp = vm.envUint("DENIM_ACTIVATION_TIMESTAMP");
        require(
            l2GenesisTimestamp <= type(uint64).max && denimActivationTimestamp <= type(uint64).max, "l2 time overflow"
        );
        require(denimActivationTimestamp != 0, "denim activation not set");
        l2GenesisTimestampEnv = uint64(l2GenesisTimestamp);
        denimActivationTimestampEnv = uint64(denimActivationTimestamp);

        currentAggregateVerifier =
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(GameType.wrap(uint32(currentGameType)));

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        aggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
        teeVerifier = vm.parseJsonAddress(json, ".teeVerifier");
        zkVerifier = vm.parseJsonAddress(json, ".zkVerifier");
    }

    function setUp() public view {
        IDisputeGameFactoryAdmin factory = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(factory.owner() == ownerSafeEnv, "factory owner mismatch");
        require(factory.gameImpls(newGameTypeEnv) == address(0), "new game type already registered");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(aggregateVerifier != address(0), "aggregate verifier not set");
        require(teeVerifier != address(0), "tee verifier not set");
        require(zkVerifier != address(0), "zk verifier not set");
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");

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

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (newGameTypeEnv, aggregateVerifier, bytes(""))
            ),
            value: 0
        });
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setInitBond, (newGameTypeEnv, initBondEnv)),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin factory = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(factory.gameImpls(newGameTypeEnv) == aggregateVerifier, "factory implementation mismatch");
        require(factory.initBonds(newGameTypeEnv) == initBondEnv, "factory init bond mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
