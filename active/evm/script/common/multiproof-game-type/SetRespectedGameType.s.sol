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

/// @notice Cuts the AnchorStateRegistry over to a preregistered multiproof game type.
contract SetRespectedGameType is MultisigScript {
    uint256 internal constant DENIM_UPGRADE_INDEX = 13;

    IAnchorStateRegistry internal immutable anchorStateRegistry;
    address internal immutable guardian;
    GameType internal immutable currentGameTypeEnv;
    GameType internal immutable newGameTypeEnv;
    IProtocolVersions internal immutable protocolVersionsEnv;
    uint64 internal immutable denimActivationTimestampEnv;
    uint64 internal immutable retirementTimestamp;

    address internal immutable aggregateVerifier;

    constructor() {
        anchorStateRegistry = IAnchorStateRegistry(vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY"));
        guardian = anchorStateRegistry.systemConfig().guardian();
        retirementTimestamp = anchorStateRegistry.retirementTimestamp();
        uint256 currentGameType = vm.envUint("CURRENT_GAME_TYPE");
        uint256 newGameType = vm.envUint("NEW_GAME_TYPE");
        require(currentGameType <= type(uint32).max && newGameType <= type(uint32).max, "game type overflow");
        currentGameTypeEnv = GameType.wrap(uint32(currentGameType));
        newGameTypeEnv = GameType.wrap(uint32(newGameType));
        protocolVersionsEnv = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS"));
        uint256 denimActivationTimestamp = vm.envUint("DENIM_ACTIVATION_TIMESTAMP");
        require(denimActivationTimestamp <= type(uint64).max, "denim activation overflow");
        require(denimActivationTimestamp != 0, "denim activation not set");
        denimActivationTimestampEnv = uint64(denimActivationTimestamp);

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        aggregateVerifier = vm.parseJsonAddress(json, ".aggregateVerifier");
    }

    function setUp() public view {
        require(
            GameType.unwrap(anchorStateRegistry.respectedGameType()) == GameType.unwrap(currentGameTypeEnv),
            "current game type not respected"
        );
        require(GameType.unwrap(currentGameTypeEnv) != GameType.unwrap(newGameTypeEnv), "game type already respected");
        address implementation = address(anchorStateRegistry.disputeGameFactory().gameImpls(newGameTypeEnv));
        require(implementation == aggregateVerifier, "registered implementation mismatch");
        AggregateVerifier aggregate = AggregateVerifier(aggregateVerifier);
        require(GameType.unwrap(aggregate.gameType()) == GameType.unwrap(newGameTypeEnv), "game type mismatch");
        require(address(aggregate.anchorStateRegistry()) == address(anchorStateRegistry), "asr mismatch");
        require(
            address(aggregate.DISPUTE_GAME_FACTORY()) == address(anchorStateRegistry.disputeGameFactory()),
            "factory mismatch"
        );
        require(aggregate.L2_BLOCK_TIME() == 2, "l2 block time mismatch");
        require(aggregate.BLOCK_INTERVAL() == 6000, "block interval mismatch");
        require(aggregate.INTERMEDIATE_BLOCK_INTERVAL() == 300, "intermediate block interval mismatch");
        require(address(aggregate.PROTOCOL_VERSIONS()) == address(protocolVersionsEnv), "protocol versions mismatch");

        uint64[] memory schedule = protocolVersionsEnv.getSchedule();
        require(
            schedule.length > DENIM_UPGRADE_INDEX && schedule[DENIM_UPGRADE_INDEX] == denimActivationTimestampEnv,
            "denim activation mismatch"
        );

        TEEVerifier tee = TEEVerifier(address(aggregate.TEE_VERIFIER()));
        require(!tee.nullified(), "tee verifier nullified");
        require(
            GameType.unwrap(tee.TEE_PROVER_REGISTRY().gameType()) == GameType.unwrap(newGameTypeEnv),
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
