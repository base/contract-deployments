// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

interface IDisputeGameFactoryAdmin {
    function gameArgs(GameType gameType) external view returns (bytes memory);
    function gameCount() external view returns (uint256);
    function gameImpls(GameType gameType) external view returns (address);
    function owner() external view returns (address);
    function setImplementation(GameType gameType, address impl) external;
}

contract UpdateCobaltVerifierHashes is MultisigScript {
    GameType internal constant GAME_TYPE = GameType.wrap(621);

    address internal immutable ownerSafe;
    IDisputeGameFactoryAdmin internal immutable disputeGameFactory;
    address internal immutable currentAggregateVerifier;
    AggregateVerifier internal immutable nextAggregateVerifier;
    bytes32 internal immutable newTeeImageHash;
    bytes32 internal immutable newZkRangeHash;
    bytes32 internal immutable newZkAggregateHash;
    uint256 internal immutable gameCountBefore;
    bytes32 internal immutable gameArgsHashBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactory = IDisputeGameFactoryAdmin(vm.envAddress("DISPUTE_GAME_FACTORY_PROXY"));
        currentAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");
        newTeeImageHash = vm.envOr("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", bytes32(0));
        newZkRangeHash = vm.envOr("AGGREGATE_VERIFIER_ZK_RANGE_HASH", bytes32(0));
        newZkAggregateHash = vm.envOr("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", bytes32(0));

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        nextAggregateVerifier = AggregateVerifier(vm.parseJsonAddress(json, ".aggregateVerifier"));
        gameCountBefore = disputeGameFactory.gameCount();
        gameArgsHashBefore = keccak256(disputeGameFactory.gameArgs(GAME_TYPE));
    }

    function setUp() public view {
        require(disputeGameFactory.owner() == ownerSafe, "dgf owner mismatch");
        require(disputeGameFactory.gameImpls(GAME_TYPE) == currentAggregateVerifier, "current verifier mismatch");
        require(address(nextAggregateVerifier).code.length != 0, "next verifier not deployed");
        require(address(nextAggregateVerifier) != currentAggregateVerifier, "next verifier equals current");
        _assertUpdatedHashes(nextAggregateVerifier);
        _assertImmutableContinuity(AggregateVerifier(currentAggregateVerifier), nextAggregateVerifier);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(disputeGameFactory),
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation, (GAME_TYPE, address(nextAggregateVerifier))
            ),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(disputeGameFactory.owner() == ownerSafe, "dgf owner changed");
        require(
            disputeGameFactory.gameImpls(GAME_TYPE) == address(nextAggregateVerifier), "aggregate verifier not updated"
        );
        require(disputeGameFactory.gameCount() == gameCountBefore, "game count changed");
        require(keccak256(disputeGameFactory.gameArgs(GAME_TYPE)) == gameArgsHashBefore, "game args changed");
        _assertUpdatedHashes(nextAggregateVerifier);
        _assertImmutableContinuity(AggregateVerifier(currentAggregateVerifier), nextAggregateVerifier);
    }

    function _assertUpdatedHashes(AggregateVerifier next) internal view {
        require(next.TEE_IMAGE_HASH() == newTeeImageHash, "tee image hash mismatch");
        require(next.ZK_RANGE_HASH() == newZkRangeHash, "zk range hash mismatch");
        require(next.ZK_AGGREGATE_HASH() == newZkAggregateHash, "zk aggregate hash mismatch");
    }

    function _assertImmutableContinuity(AggregateVerifier current, AggregateVerifier next) internal view {
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(current.gameType()), "game type changed");
        require(address(next.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr changed");
        require(address(next.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()), "dgf changed");
        require(address(next.DELAYED_WETH()) == address(current.DELAYED_WETH()), "delayed weth changed");
        require(address(next.TEE_VERIFIER()) == address(current.TEE_VERIFIER()), "tee verifier changed");
        require(address(next.ZK_VERIFIER()) == address(current.ZK_VERIFIER()), "zk verifier changed");
        require(next.CONFIG_HASH() == current.CONFIG_HASH(), "config hash changed");
        require(next.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "l2 chain id changed");
        require(next.BLOCK_INTERVAL() == current.BLOCK_INTERVAL(), "block interval changed");
        require(
            next.INTERMEDIATE_BLOCK_INTERVAL() == current.INTERMEDIATE_BLOCK_INTERVAL(),
            "intermediate block interval changed"
        );
        require(address(next.PROTOCOL_VERSIONS()) == address(current.PROTOCOL_VERSIONS()), "registry changed");
        require(next.L2_GENESIS_BLOCK_NUMBER() == current.L2_GENESIS_BLOCK_NUMBER(), "genesis block changed");
        require(next.L2_GENESIS_TIMESTAMP() == current.L2_GENESIS_TIMESTAMP(), "genesis timestamp changed");
        require(next.L2_BLOCK_TIME() == current.L2_BLOCK_TIME(), "l2 block time changed");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
