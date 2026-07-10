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

/// @notice Updates the live multiproof implementation to an AggregateVerifier wired to the new ZkVerifier.
contract ReplayUpdateZkConfig is MultisigScript {
    address internal immutable OWNER_SAFE_ENV = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    GameType internal immutable GAME_TYPE_ENV = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
    address internal immutable SP1_VERIFIER_ENV = vm.envAddress("SP1_VERIFIER");

    address internal currentAggregateVerifier;
    address internal currentZkVerifier;
    address internal nextAggregateVerifier;
    address internal nextZkVerifier;
    GameType internal nextGameType;

    function setUp() public {
        require(
            IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV).owner() == OWNER_SAFE_ENV, "dgf owner mismatch"
        );

        currentAggregateVerifier = IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(GAME_TYPE_ENV);
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(GAME_TYPE_ENV), "current game type mismatch"
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
        require(SP1_VERIFIER_ENV != address(0), "sp1 verifier not set");

        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);
        nextGameType = nextAggregate.gameType();

        require(GameType.unwrap(nextGameType) == GameType.unwrap(GAME_TYPE_ENV), "next game type mismatch");
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == SP1_VERIFIER_ENV, "next zk verifier sp1 mismatch");
        require(
            address(ZkVerifier(nextZkVerifier).ANCHOR_STATE_REGISTRY())
                == address(currentAggregate.anchorStateRegistry()),
            "next zk verifier asr mismatch"
        );

        _assertImmutableContinuity(currentAggregate, nextAggregate);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: DISPUTE_GAME_FACTORY_PROXY_ENV,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (nextGameType, nextAggregateVerifier, "")),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(DISPUTE_GAME_FACTORY_PROXY_ENV);
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        require(dgf.gameImpls(nextGameType) == nextAggregateVerifier, "dgf aggregate verifier mismatch");
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(address(ZkVerifier(nextZkVerifier).SP1_VERIFIER()) == SP1_VERIFIER_ENV, "next zk verifier sp1 mismatch");
        _assertImmutableContinuity(currentAggregate, nextAggregate);
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
        require(nextAggregate.TEE_IMAGE_HASH() == currentAggregate.TEE_IMAGE_HASH(), "tee image hash changed");
        require(nextAggregate.ZK_RANGE_HASH() == currentAggregate.ZK_RANGE_HASH(), "zk range hash changed");
        require(nextAggregate.ZK_AGGREGATE_HASH() == currentAggregate.ZK_AGGREGATE_HASH(), "zk aggregate hash changed");
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
        require(nextAggregate.PROOF_THRESHOLD() == currentAggregate.PROOF_THRESHOLD(), "proof threshold mismatch");
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE_ENV;
    }
}
