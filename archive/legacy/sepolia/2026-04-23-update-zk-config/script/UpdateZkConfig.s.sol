// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

/// @notice Updates the live multiproof implementation in the DisputeGameFactory to the newly
/// deployed AggregateVerifier carrying the new verifier config.
contract UpdateZkConfig is MultisigScript {
    // Task config from .env.
    address internal ownerSafeEnv;
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal sp1VerifierEnv;
    bytes32 internal zkRangeHashEnv;

    // Live onchain state.
    address internal currentAggregateVerifier;
    address internal currentZkVerifier;

    // Deployment outputs produced by the EOA scripts and read from addresses.json.
    address internal nextAggregateVerifier;
    address internal nextZkVerifier;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierEnv = vm.envAddress("SP1_VERIFIER");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");

        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        currentZkVerifier = address(currentAggregate.ZK_VERIFIER());

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});

        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");
        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(nextZkVerifier != currentZkVerifier, "next zk verifier equals current");
        require(sp1VerifierEnv != address(0), "sp1 verifier not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");

        _checkNextAggregate(currentAggregate, AggregateVerifier(nextAggregateVerifier));
        _checkNextZkVerifier(currentAggregate);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (gameTypeEnv, nextAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv) == nextAggregateVerifier,
            "dgf aggregate verifier mismatch"
        );

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        _checkNextAggregate(currentAggregate, AggregateVerifier(nextAggregateVerifier));
        _checkNextZkVerifier(currentAggregate);
    }

    function _checkNextAggregate(AggregateVerifier currentAggregate, AggregateVerifier nextAggregate) internal view {
        require(GameType.unwrap(nextAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "next game type mismatch");
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
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(
            nextAggregate.TEE_IMAGE_HASH() == currentAggregate.TEE_IMAGE_HASH(),
            "next aggregate tee image hash mismatch"
        );
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(
            nextAggregate.ZK_AGGREGATE_HASH() == currentAggregate.ZK_AGGREGATE_HASH(),
            "next aggregate zk aggregate hash mismatch"
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
        require(
            nextAggregate.PROOF_THRESHOLD() == currentAggregate.PROOF_THRESHOLD(),
            "next aggregate proof threshold mismatch"
        );
    }

    function _checkNextZkVerifier(AggregateVerifier currentAggregate) internal view {
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY()) == address(currentAggregate.anchorStateRegistry()),
            "next zk verifier asr mismatch"
        );
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "next zk verifier sp1 mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
