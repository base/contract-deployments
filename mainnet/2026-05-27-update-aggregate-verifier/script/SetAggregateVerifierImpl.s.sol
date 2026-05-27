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
///         rollback by varying `TARGET_AGGREGATE_VERIFIER` and
///         `ASSUMED_CURRENT_AGGREGATE_VERIFIER`:
///           - upgrade flow:
///               * TARGET                  = NEW (addresses.json)
///               * ASSUMED_CURRENT         = OLD (= live chain pre-upgrade)
///           - rollback flow:
///               * TARGET                  = OLD
///               * ASSUMED_CURRENT         = NEW (= live chain post-upgrade)
///
///         If the simulation runs against a chain that has not yet executed
///         the upgrade, the rollback simulation will see
///         `DGF.gameImpls(GAME_TYPE) == OLD`, which differs from the assumed
///         NEW. In that case `_simulationOverrides()` rewrites the
///         `gameImpls[GAME_TYPE]` storage slot to `ASSUMED_CURRENT` so the
///         simulated rollback shows a real state diff (NEW -> OLD) for
///         signers. This mirrors the pattern in
///         `mainnet/2026-03-25-increase-gas-and-elasticity-limit`.
///
///         Continuity is enforced by asserting that every immutable on the
///         target AggregateVerifier matches `ASSUMED_CURRENT`, except for the
///         three hashes (`TEE_IMAGE_HASH`, `ZK_RANGE_HASH`,
///         `ZK_AGGREGATE_HASH`). This holds in both directions.
contract SetAggregateVerifierImpl is MultisigScript {
    /// @dev Storage slot of `gameImpls` in `DisputeGameFactory`, from the
    ///      pinned base-contracts storage layout snapshot
    ///      (`lib/contracts/snapshots/storageLayout/DisputeGameFactory.json`).
    uint256 internal constant GAME_IMPLS_SLOT = 101;

    address internal immutable OWNER_SAFE_ENV;
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV;
    GameType internal immutable GAME_TYPE_ENV;
    address internal immutable TARGET_AGGREGATE_VERIFIER_ENV;
    address internal immutable ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV;

    constructor() {
        OWNER_SAFE_ENV = vm.envAddress("PROXY_ADMIN_OWNER");
        DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        GAME_TYPE_ENV = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        TARGET_AGGREGATE_VERIFIER_ENV = vm.envAddress("TARGET_AGGREGATE_VERIFIER");
        ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV = vm.envAddress("ASSUMED_CURRENT_AGGREGATE_VERIFIER");
    }

    function setUp() public view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: DISPUTE_GAME_FACTORY_PROXY_ENV,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation,
                (GAME_TYPE_ENV, TARGET_AGGREGATE_VERIFIER_ENV, "")
            ),
            value: 0
        });

        return calls;
    }

    /// @dev Forces the simulation to see `DGF.gameImpls[GAME_TYPE]` equal to
    ///      `ASSUMED_CURRENT_AGGREGATE_VERIFIER`. No-op when the live chain
    ///      already matches the assumed pre-state.
    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory) {
        address liveCurrent =
            IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(GAME_TYPE_ENV);
        if (liveCurrent == ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV) {
            return new Simulation.StateOverride[](0);
        }

        Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);

        storageOverrides[0] = Simulation.StorageOverride({
            key: _gameImplsSlotKey(GAME_TYPE_ENV),
            value: bytes32(uint256(uint160(ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV)))
        });

        stateOverrides[0] = Simulation.StateOverride({
            contractAddress: DISPUTE_GAME_FACTORY_PROXY_ENV,
            overrides: storageOverrides
        });

        return stateOverrides;
    }

    function _preCheck() internal view {
        require(
            IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV).owner() == OWNER_SAFE_ENV,
            "DGF owner != PROXY_ADMIN_OWNER"
        );

        require(
            ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV != address(0),
            "assumed current aggregate verifier not set"
        );
        require(TARGET_AGGREGATE_VERIFIER_ENV != address(0), "target aggregate verifier not set");
        require(
            TARGET_AGGREGATE_VERIFIER_ENV != ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV,
            "target equals assumed current (no-op)"
        );

        AggregateVerifier assumedCurrent = AggregateVerifier(ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV);
        AggregateVerifier target = AggregateVerifier(TARGET_AGGREGATE_VERIFIER_ENV);

        require(
            GameType.unwrap(assumedCurrent.gameType()) == GameType.unwrap(GAME_TYPE_ENV),
            "assumed current game type mismatch"
        );
        require(
            GameType.unwrap(target.gameType()) == GameType.unwrap(GAME_TYPE_ENV),
            "target game type mismatch"
        );

        // Every non-hash immutable must match between assumed current and target.
        _assertImmutableContinuity(assumedCurrent, target);
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV);
        require(
            dgf.gameImpls(GAME_TYPE_ENV) == TARGET_AGGREGATE_VERIFIER_ENV,
            "game impl not set to target"
        );

        // Re-run the continuity check against the assumed-current vs target pair.
        AggregateVerifier assumedCurrent = AggregateVerifier(ASSUMED_CURRENT_AGGREGATE_VERIFIER_ENV);
        AggregateVerifier target = AggregateVerifier(TARGET_AGGREGATE_VERIFIER_ENV);
        _assertImmutableContinuity(assumedCurrent, target);
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

    /// @dev Storage slot key for `gameImpls[gameType]` in the
    ///      `DisputeGameFactory` proxy. For a Solidity
    ///      `mapping(GameType => IDisputeGame)` at storage slot `p`, the slot
    ///      for `mapping[k]` is `keccak256(abi.encode(k, p))` (the key is
    ///      left-padded to 32 bytes by `abi.encode`).
    function _gameImplsSlotKey(GameType gameType) internal pure returns (bytes32) {
        return keccak256(abi.encode(gameType, GAME_IMPLS_SLOT));
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE_ENV;
    }
}
