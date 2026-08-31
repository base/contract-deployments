// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";

import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/L1/proofs/tee/TEEVerifier.sol";
import {ZKVerifier} from "@base-contracts/src/L1/proofs/zk/ZKVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

library MultiproofGameTypeChecks {
    uint256 internal constant DENIM_UPGRADE_INDEX = 13;
    uint256 internal constant BLOCK_INTERVAL = 6000;
    uint256 internal constant INTERMEDIATE_BLOCK_INTERVAL = 300;
    uint64 internal constant L2_BLOCK_TIME = 2;

    struct Expected {
        GameType gameType;
        address disputeGameFactory;
        address teeVerifier;
        address zkVerifier;
        bytes32 teeImageHash;
        bytes32 zkRangeHash;
        bytes32 zkAggregateHash;
        IProtocolVersions protocolVersions;
        uint256 l2GenesisBlockNumber;
        uint64 l2GenesisTimestamp;
        uint64 denimActivationTimestamp;
    }

    function assertDeployment(AggregateVerifier aggregate, AggregateVerifier current, Expected memory expected)
        internal
        view
    {
        require(GameType.unwrap(aggregate.gameType()) == GameType.unwrap(expected.gameType), "game type mismatch");
        require(address(current.DISPUTE_GAME_FACTORY()) == expected.disputeGameFactory, "current factory mismatch");
        require(address(aggregate.DISPUTE_GAME_FACTORY()) == expected.disputeGameFactory, "factory mismatch");
        require(address(aggregate.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr mismatch");
        require(
            GameType.unwrap(current.anchorStateRegistry().respectedGameType()) == GameType.unwrap(current.gameType()),
            "current game type not respected"
        );
        require(address(aggregate.DELAYED_WETH()) == address(current.DELAYED_WETH()), "delayed weth mismatch");
        require(address(aggregate.TEE_VERIFIER()) == expected.teeVerifier, "tee verifier mismatch");
        require(address(aggregate.ZK_VERIFIER()) == expected.zkVerifier, "zk verifier mismatch");
        require(expected.teeVerifier != address(current.TEE_VERIFIER()), "tee verifier not fresh");
        require(expected.zkVerifier != address(current.ZK_VERIFIER()), "zk verifier not fresh");
        require(aggregate.TEE_IMAGE_HASH() == expected.teeImageHash, "tee image hash mismatch");
        require(aggregate.ZK_RANGE_HASH() == expected.zkRangeHash, "zk range hash mismatch");
        require(aggregate.ZK_AGGREGATE_HASH() == expected.zkAggregateHash, "zk aggregate hash mismatch");
        require(aggregate.CONFIG_HASH() == current.CONFIG_HASH(), "config hash mismatch");
        require(aggregate.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(aggregate.L2_GENESIS_BLOCK_NUMBER() == expected.l2GenesisBlockNumber, "genesis block mismatch");
        require(aggregate.L2_GENESIS_TIMESTAMP() == expected.l2GenesisTimestamp, "genesis timestamp mismatch");
        require(aggregate.L2_BLOCK_TIME() == L2_BLOCK_TIME, "l2 block time mismatch");
        require(aggregate.BLOCK_INTERVAL() == BLOCK_INTERVAL, "block interval mismatch");
        require(
            aggregate.INTERMEDIATE_BLOCK_INTERVAL() == INTERMEDIATE_BLOCK_INTERVAL,
            "intermediate block interval mismatch"
        );
        require(
            address(aggregate.PROTOCOL_VERSIONS()) == address(expected.protocolVersions), "protocol versions mismatch"
        );
        require(
            aggregate.intermediateOutputRootsCount() == BLOCK_INTERVAL / INTERMEDIATE_BLOCK_INTERVAL,
            "intermediate root count mismatch"
        );

        TEEVerifier tee = TEEVerifier(expected.teeVerifier);
        TEEVerifier currentTee = TEEVerifier(address(current.TEE_VERIFIER()));
        require(!tee.nullified(), "tee verifier nullified");
        require(
            address(tee.TEE_PROVER_REGISTRY()) == address(currentTee.TEE_PROVER_REGISTRY()), "tee registry mismatch"
        );
        require(address(tee.ANCHOR_STATE_REGISTRY()) == address(current.anchorStateRegistry()), "tee asr mismatch");

        ZKVerifier zk = ZKVerifier(expected.zkVerifier);
        ZKVerifier currentZk = ZKVerifier(address(current.ZK_VERIFIER()));
        require(!zk.nullified(), "zk verifier nullified");
        require(address(zk.SP1_VERIFIER()) == address(currentZk.SP1_VERIFIER()), "zk sp1 verifier mismatch");
        require(address(zk.ANCHOR_STATE_REGISTRY()) == address(current.anchorStateRegistry()), "zk asr mismatch");

        uint64[] memory schedule = expected.protocolVersions.getSchedule();
        require(
            schedule.length > DENIM_UPGRADE_INDEX && schedule[DENIM_UPGRADE_INDEX] == expected.denimActivationTimestamp,
            "denim activation mismatch"
        );
    }
}
