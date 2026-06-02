// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Updates the live multiproof implementation in the DisputeGameFactory to
/// the newly deployed AggregateVerifier carrying updated TEE_IMAGE_HASH,
/// ZK_RANGE_HASH, and ZK_AGGREGATE_HASH.
contract UpdateVerifierHashes is MultisigScript {
    // Task config from .env.
    address internal ownerSafeEnv;
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;

    // Live onchain state.
    address internal currentAggregateVerifier;

    // Deployment output produced by the EOA script and read from addresses.json.
    address internal nextAggregateVerifier;
    GameType internal nextGameType;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");

        nextGameType = AggregateVerifier(nextAggregateVerifier).gameType();

        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");

        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );

        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");

        // Validate the new AggregateVerifier carries the expected hashes.
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");
        require(nextAggregate.TEE_IMAGE_HASH() == teeImageHashEnv, "next aggregate tee image hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");

        // Validate all other immutables are preserved.
        require(
            address(nextAggregate.anchorStateRegistry()) == address(currentAggregate.anchorStateRegistry()),
            "next aggregate asr mismatch"
        );
        require(
            address(nextAggregate.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "next aggregate dgf mismatch"
        );
        require(
            address(nextAggregate.DELAYED_WETH()) == address(currentAggregate.DELAYED_WETH()),
            "next aggregate delayed weth mismatch"
        );
        require(
            address(nextAggregate.TEE_VERIFIER()) == address(currentAggregate.TEE_VERIFIER()),
            "next aggregate tee verifier mismatch"
        );
        require(
            address(nextAggregate.ZK_VERIFIER()) == address(currentAggregate.ZK_VERIFIER()),
            "next aggregate zk verifier mismatch"
        );
        require(nextAggregate.CONFIG_HASH() == currentAggregate.CONFIG_HASH(), "next aggregate config hash mismatch");
        require(nextAggregate.L2_CHAIN_ID() == currentAggregate.L2_CHAIN_ID(), "next aggregate l2 chain id mismatch");
        require(
            nextAggregate.BLOCK_INTERVAL() == currentAggregate.BLOCK_INTERVAL(),
            "next aggregate block interval mismatch"
        );
        require(
            nextAggregate.INTERMEDIATE_BLOCK_INTERVAL() == currentAggregate.INTERMEDIATE_BLOCK_INTERVAL(),
            "next aggregate intermediate interval mismatch"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (nextGameType, nextAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        // Verify DGF now points to the new AggregateVerifier.
        require(dgf.gameImpls(nextGameType) == nextAggregateVerifier, "dgf aggregate verifier mismatch");

        // Verify updated hashes.
        require(nextAggregate.TEE_IMAGE_HASH() == teeImageHashEnv, "next aggregate tee image hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");

        // Verify all other immutables are preserved.
        require(
            address(nextAggregate.anchorStateRegistry()) == address(currentAggregate.anchorStateRegistry()),
            "next aggregate asr mismatch"
        );
        require(
            address(nextAggregate.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "next aggregate dgf mismatch"
        );
        require(
            address(nextAggregate.DELAYED_WETH()) == address(currentAggregate.DELAYED_WETH()),
            "next aggregate delayed weth mismatch"
        );
        require(
            address(nextAggregate.TEE_VERIFIER()) == address(currentAggregate.TEE_VERIFIER()),
            "next aggregate tee verifier mismatch"
        );
        require(
            address(nextAggregate.ZK_VERIFIER()) == address(currentAggregate.ZK_VERIFIER()),
            "next aggregate zk verifier mismatch"
        );
        require(nextAggregate.CONFIG_HASH() == currentAggregate.CONFIG_HASH(), "next aggregate config hash mismatch");
        require(nextAggregate.L2_CHAIN_ID() == currentAggregate.L2_CHAIN_ID(), "next aggregate l2 chain id mismatch");
        require(
            nextAggregate.BLOCK_INTERVAL() == currentAggregate.BLOCK_INTERVAL(),
            "next aggregate block interval mismatch"
        );
        require(
            nextAggregate.INTERMEDIATE_BLOCK_INTERVAL() == currentAggregate.INTERMEDIATE_BLOCK_INTERVAL(),
            "next aggregate intermediate interval mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
