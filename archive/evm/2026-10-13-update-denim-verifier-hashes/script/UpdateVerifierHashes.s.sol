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

/// @notice Registers the redeployed AggregateVerifier 0.3.0 for the multiproof game type. It differs from the
///         current verifier only by its TEE_IMAGE_HASH, ZK_RANGE_HASH and ZK_AGGREGATE_HASH.
contract UpdateVerifierHashes is MultisigScript {
    string internal constant VERSION = "0.3.0";

    // Task config from .env.
    address internal immutable ownerSafe;
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable currentAggregateVerifier;
    address internal immutable newAggregateVerifier;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;

    // Live state captured at construction and re-asserted after execution.
    uint256 internal immutable gameCountBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameType = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        currentAggregateVerifier = vm.envAddress("CURRENT_AGGREGATE_VERIFIER");
        newAggregateVerifier = vm.envAddress("NEW_AGGREGATE_VERIFIER");
        teeImageHash = vm.envBytes32("AGGREGATE_VERIFIER_TEE_IMAGE_HASH");
        zkRangeHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_RANGE_HASH");
        zkAggregateHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH");

        gameCountBefore = IDisputeGameFactoryAdmin(disputeGameFactory).gameCount();
    }

    function setUp() public view {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);

        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(dgf.gameImpls(gameType) == currentAggregateVerifier, "unexpected current aggregate verifier");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args not empty");
        require(_eq(AggregateVerifier(currentAggregateVerifier).version(), VERSION), "unexpected current version");
        require(newAggregateVerifier.code.length != 0, "new aggregate verifier not deployed");
        require(newAggregateVerifier != currentAggregateVerifier, "new aggregate verifier is the current one");
        require(_eq(AggregateVerifier(newAggregateVerifier).version(), VERSION), "new version mismatch");
        _assertNewVerifier();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (gameType, newAggregateVerifier)),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);

        require(dgf.gameImpls(gameType) == newAggregateVerifier, "aggregate verifier not registered");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args changed");
        require(dgf.gameCount() == gameCountBefore, "game count changed");

        _assertNewVerifier();
    }

    /// @dev Checks the new verifier's hashes against config and every other immutable against the current
    ///      verifier.
    function _assertNewVerifier() internal view {
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);

        require(av.TEE_IMAGE_HASH() == teeImageHash, "tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "zk aggregate hash mismatch");

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(current.gameType()), "game type mismatch");
        require(address(av.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()), "dgf mismatch");
        require(address(av.DELAYED_WETH()) == address(current.DELAYED_WETH()), "delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == address(current.TEE_VERIFIER()), "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == address(current.ZK_VERIFIER()), "zk verifier mismatch");
        require(av.CONFIG_HASH() == current.CONFIG_HASH(), "config hash mismatch");
        require(av.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(av.SLOW_BLOCK_INTERVAL() == current.SLOW_BLOCK_INTERVAL(), "slow block interval mismatch");
        require(
            av.SLOW_INTERMEDIATE_BLOCK_INTERVAL() == current.SLOW_INTERMEDIATE_BLOCK_INTERVAL(),
            "slow intermediate mismatch"
        );
        require(av.FAST_BLOCK_INTERVAL() == current.FAST_BLOCK_INTERVAL(), "fast block interval mismatch");
        require(
            av.FAST_INTERMEDIATE_BLOCK_INTERVAL() == current.FAST_INTERMEDIATE_BLOCK_INTERVAL(),
            "fast intermediate mismatch"
        );
        require(address(av.PROTOCOL_VERSIONS()) == address(current.PROTOCOL_VERSIONS()), "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == current.L2_GENESIS_BLOCK_NUMBER(), "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == current.L2_GENESIS_TIMESTAMP(), "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == current.L2_BLOCK_TIME(), "l2 block time mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
