// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Calls `DisputeGameFactory.setImplementation(GAME_TYPE, TARGET_AGGREGATE_VERIFIER, "")`
///         from the `PROXY_ADMIN_OWNER` 2/2 nested safe.
///
///         The same script is reused for both the forward upgrade and the
///         rollback by varying `TARGET_AGGREGATE_VERIFIER`:
///           - upgrade:  the freshly deployed AggregateVerifier (addresses.json)
///           - rollback: the previously registered AggregateVerifier
///                       (`OLD_AGGREGATE_VERIFIER` from `.env`).
///
///         Continuity is enforced by asserting that every immutable on the
///         target AggregateVerifier matches the AggregateVerifier currently
///         registered in the DisputeGameFactory, except for the three hashes
///         (`TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, `ZK_AGGREGATE_HASH`). This
///         check is direction-agnostic: it holds for both the upgrade and
///         the rollback.
contract SetAggregateVerifierImpl is MultisigScript {
    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    address internal immutable targetAggregateVerifierEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal immutable currentAggregateVerifier;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        targetAggregateVerifierEnv = vm.envAddress("TARGET_AGGREGATE_VERIFIER");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);
    }

    function setUp() public view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation,
                (gameTypeEnv, targetAggregateVerifierEnv, "")
            ),
            value: 0
        });

        return calls;
    }

    function _preCheck() internal view {
        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv,
            "DGF owner != PROXY_ADMIN_OWNER"
        );

        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(targetAggregateVerifierEnv != address(0), "target aggregate verifier not set");
        require(targetAggregateVerifierEnv != currentAggregateVerifier, "target equals current (no-op)");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier targetAggregate = AggregateVerifier(targetAggregateVerifierEnv);

        // GameType is preserved and matches the env-declared value.
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv),
            "current game type mismatch"
        );
        require(
            GameType.unwrap(targetAggregate.gameType()) == GameType.unwrap(gameTypeEnv),
            "target game type mismatch"
        );

        // Every non-hash immutable must match between current and target.
        _assertImmutableContinuity(currentAggregate, targetAggregate);
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(
            dgf.gameImpls(gameTypeEnv) == targetAggregateVerifierEnv,
            "game impl not set to target"
        );

        // Re-run the continuity check against the now-registered target.
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier targetAggregate = AggregateVerifier(targetAggregateVerifierEnv);
        _assertImmutableContinuity(currentAggregate, targetAggregate);
    }

    /// @dev Asserts that every immutable on `target` matches `current`, except
    ///      for the three hashes that this task is explicitly rotating.
    function _assertImmutableContinuity(AggregateVerifier current, AggregateVerifier target) internal view {
        require(
            address(target.anchorStateRegistry()) == address(current.anchorStateRegistry()),
            "target asr mismatch"
        );
        require(
            address(target.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()),
            "target dgf mismatch"
        );
        require(
            address(target.DELAYED_WETH()) == address(current.DELAYED_WETH()),
            "target delayed weth mismatch"
        );
        require(
            address(target.TEE_VERIFIER()) == address(current.TEE_VERIFIER()),
            "target tee verifier mismatch"
        );
        require(
            address(target.ZK_VERIFIER()) == address(current.ZK_VERIFIER()),
            "target zk verifier mismatch"
        );
        require(target.CONFIG_HASH() == current.CONFIG_HASH(), "target config hash mismatch");
        require(target.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "target l2 chain id mismatch");
        require(target.BLOCK_INTERVAL() == current.BLOCK_INTERVAL(), "target block interval mismatch");
        require(
            target.INTERMEDIATE_BLOCK_INTERVAL() == current.INTERMEDIATE_BLOCK_INTERVAL(),
            "target intermediate interval mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
