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

/// @notice Points the DisputeGameFactory at the AggregateVerifier with updated ZK program hashes.
contract UpdateZkProgramHashes is MultisigScript {
    GameType internal constant GAME_TYPE = GameType.wrap(621);

    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;

    address internal immutable currentAggregateVerifier;
    address internal immutable nextAggregateVerifier;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(GAME_TYPE);

        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/addresses.json"));
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
    }

    function setUp() public view {
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(nextAggregateVerifier != address(0) && nextAggregateVerifier != currentAggregateVerifier, "bad next av");
        require(zkRangeHashEnv != bytes32(0) && zkAggregateHashEnv != bytes32(0), "zk hashes not set");

        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier next = AggregateVerifier(nextAggregateVerifier);
        require(GameType.unwrap(current.gameType()) == GameType.unwrap(GAME_TYPE), "current game type mismatch");
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(GAME_TYPE), "next game type mismatch");

        _assertHashes(current, next);
        _assertContinuity(current, next);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (GAME_TYPE, nextAggregateVerifier, "")),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier next = AggregateVerifier(nextAggregateVerifier);

        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(GAME_TYPE) == nextAggregateVerifier,
            "dgf mismatch"
        );
        _assertHashes(current, next);
        _assertContinuity(current, next);
    }

    function _assertHashes(AggregateVerifier current, AggregateVerifier next) internal view {
        require(next.TEE_IMAGE_HASH() == current.TEE_IMAGE_HASH(), "tee hash changed");
        require(next.ZK_RANGE_HASH() == zkRangeHashEnv, "zk range hash mismatch");
        require(next.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "zk aggregate hash mismatch");
    }

    function _assertContinuity(AggregateVerifier current, AggregateVerifier next) internal view {
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(current.gameType()), "game type mismatch");
        require(address(next.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr mismatch");
        require(address(next.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()), "dgf mismatch");
        require(address(next.DELAYED_WETH()) == address(current.DELAYED_WETH()), "delayed weth mismatch");
        require(address(next.TEE_VERIFIER()) == address(current.TEE_VERIFIER()), "tee verifier mismatch");
        require(address(next.ZK_VERIFIER()) == address(current.ZK_VERIFIER()), "zk verifier mismatch");
        require(next.CONFIG_HASH() == current.CONFIG_HASH(), "config hash mismatch");
        require(next.L2_CHAIN_ID() == current.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(next.BLOCK_INTERVAL() == current.BLOCK_INTERVAL(), "block interval mismatch");
        require(
            next.INTERMEDIATE_BLOCK_INTERVAL() == current.INTERMEDIATE_BLOCK_INTERVAL(),
            "intermediate interval mismatch"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
