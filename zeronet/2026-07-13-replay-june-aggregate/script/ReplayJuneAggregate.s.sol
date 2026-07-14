// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Replays the June 2026 Zeronet task aggregate that shared the same base-contracts commit.
contract ReplayJuneAggregate is MultisigScript {
    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    bytes32 internal immutable teeImageHashEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;
    bytes32 internal immutable configHashEnv;

    address internal immutable currentAggregateVerifier;
    address internal immutable nextAggregateVerifier;
    GameType internal immutable nextGameType;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});

        nextGameType = AggregateVerifier(nextAggregateVerifier).gameType();
    }

    function setUp() public view {
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");

        _assertUpdatedHashes(nextAggregate);
        _assertImmutableContinuity(currentAggregate, nextAggregate);
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

        require(dgf.gameImpls(nextGameType) == nextAggregateVerifier, "dgf aggregate verifier mismatch");
        _assertUpdatedHashes(nextAggregate);
        _assertImmutableContinuity(currentAggregate, nextAggregate);
    }

    function _assertUpdatedHashes(AggregateVerifier nextAggregate) internal view {
        require(nextAggregate.TEE_IMAGE_HASH() == teeImageHashEnv, "next aggregate tee image hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");
        require(nextAggregate.CONFIG_HASH() == configHashEnv, "next aggregate config hash mismatch");
    }

    function _assertImmutableContinuity(AggregateVerifier currentAggregate, AggregateVerifier nextAggregate)
        internal
        view
    {
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
