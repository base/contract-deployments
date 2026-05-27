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
///         No other state on the DGF, ASR, OptimismPortal2, TEEProverRegistry,
///         DelayedWETH, TEEVerifier, or ZkVerifier is touched.
contract SetAggregateVerifierImpl is MultisigScript {
    address internal ownerSafeEnv;
    address internal disputeGameFactoryProxyEnv;
    address internal anchorStateRegistryProxyEnv;

    uint32 internal gameTypeEnv;
    address internal targetAggregateVerifierEnv;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        targetAggregateVerifierEnv = vm.envAddress("TARGET_AGGREGATE_VERIFIER");

        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(
                IDisputeGameFactoryAdmin.setImplementation,
                (GameType.wrap(gameTypeEnv), targetAggregateVerifierEnv, "")
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

        AggregateVerifier av = AggregateVerifier(targetAggregateVerifierEnv);
        require(GameType.unwrap(av.gameType()) == gameTypeEnv, "target gameType mismatch");
        require(
            address(av.anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "target anchor state registry mismatch"
        );
        require(
            address(av.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv,
            "target dispute game factory mismatch"
        );
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv);
        require(
            dgf.gameImpls(GameType.wrap(gameTypeEnv)) == targetAggregateVerifierEnv,
            "game impl not set to target"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
