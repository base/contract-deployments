// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {IAnchorStateRegistry} from "interfaces/L1/proofs/IAnchorStateRegistry.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/L1/proofs/tee/TEEVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

import {MultiproofGameTypeChecks} from "./MultiproofGameTypeChecks.sol";

/// @notice Cuts the AnchorStateRegistry over to a preregistered multiproof game type.
contract SetRespectedGameType is MultisigScript {
    IAnchorStateRegistry internal immutable anchorStateRegistry;
    address internal immutable guardian;
    GameType internal immutable newGameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;
    IProtocolVersions internal immutable protocolVersionsEnv;
    uint256 internal immutable l2GenesisBlockNumberEnv;
    uint64 internal immutable l2GenesisTimestampEnv;
    uint64 internal immutable denimActivationTimestampEnv;
    uint64 internal immutable retirementTimestamp;

    address internal immutable currentAggregateVerifier;
    address internal immutable aggregateVerifier;
    address internal immutable teeVerifier;
    address internal immutable zkVerifier;

    constructor() {
        anchorStateRegistry = IAnchorStateRegistry(vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY"));
        guardian = anchorStateRegistry.systemConfig().guardian();
        retirementTimestamp = anchorStateRegistry.retirementTimestamp();
        uint256 currentGameType = vm.envUint("CURRENT_GAME_TYPE");
        uint256 newGameType = vm.envUint("NEW_GAME_TYPE");
        require(currentGameType <= type(uint32).max && newGameType <= type(uint32).max, "game type overflow");
        newGameTypeEnv = GameType.wrap(uint32(newGameType));
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
            address(anchorStateRegistry.disputeGameFactory().gameImpls(GameType.wrap(uint32(currentGameType))));
        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        aggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
        teeVerifier = vm.parseJsonAddress(json, ".teeVerifier");
        zkVerifier = vm.parseJsonAddress(json, ".zkVerifier");
    }

    function setUp() public view {
        require(
            GameType.unwrap(anchorStateRegistry.respectedGameType()) != GameType.unwrap(newGameTypeEnv),
            "game type already respected"
        );
        address implementation = address(anchorStateRegistry.disputeGameFactory().gameImpls(newGameTypeEnv));
        require(implementation == aggregateVerifier, "registered implementation mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        MultiproofGameTypeChecks.assertDeployment(
            AggregateVerifier(aggregateVerifier),
            AggregateVerifier(currentAggregateVerifier),
            MultiproofGameTypeChecks.Expected({
                gameType: newGameTypeEnv,
                disputeGameFactory: address(anchorStateRegistry.disputeGameFactory()),
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
        require(
            GameType.unwrap(TEEVerifier(teeVerifier).TEE_PROVER_REGISTRY().gameType())
                == GameType.unwrap(newGameTypeEnv),
            "tee registry not cut over"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(anchorStateRegistry),
            data: abi.encodeCall(IAnchorStateRegistry.setRespectedGameType, (newGameTypeEnv)),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(
            GameType.unwrap(anchorStateRegistry.respectedGameType()) == GameType.unwrap(newGameTypeEnv),
            "respected game type mismatch"
        );
        require(anchorStateRegistry.retirementTimestamp() == retirementTimestamp, "retirement timestamp changed");
    }

    function _ownerSafe() internal view override returns (address) {
        return guardian;
    }
}
