// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

interface IDisputeGameFactoryAdmin {
    function owner() external view returns (address);
    function gameImpls(GameType gameType) external view returns (address);
    function setImplementation(GameType gameType, address impl, bytes calldata args) external;
}

interface ISP1VerifierGatewayView {
    function owner() external view returns (address);
    function routes(bytes4 selector) external view returns (address verifier, bool frozen);
    function addRoute(address verifier) external;
}

interface ISP1VerifierWithHashView {
    function VERIFIER_HASH() external view returns (bytes32);
}

/// @notice Points the live multiproof implementation at a ZkVerifier backed by a PROXY_ADMIN_OWNER-owned SP1 gateway.
contract UpdateSp1Gateway is MultisigScript {
    // Task config from .env.
    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    address internal immutable sp1VerifierRouteEnv;

    // Live onchain state.
    address internal immutable currentAggregateVerifier;

    // Deployment outputs produced by the EOA scripts and read from addresses.json.
    address internal immutable sp1VerifierGateway;
    address internal immutable nextZkVerifier;
    address internal immutable nextAggregateVerifier;

    // AggregateVerifier metadata used by the multisig update call and post-checks.
    GameType internal immutable nextGameType;

    // Derived route metadata.
    bytes4 internal immutable sp1VerifierSelector;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        sp1VerifierGateway = vm.parseJsonAddress({json: json, key: ".sp1VerifierGateway"});
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});

        nextGameType = AggregateVerifier(nextAggregateVerifier).gameType();
        sp1VerifierSelector = bytes4(ISP1VerifierWithHashView(sp1VerifierRouteEnv).VERIFIER_HASH());
    }

    function setUp() public view {
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(sp1VerifierGateway != address(0), "sp1 verifier gateway not set");
        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);

        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");

        _assertGatewayReadyForRouteAdd();
        _assertZkVerifierConfigured(currentAggregate, nextZkVerifier);
        _assertAggregateVerifierConfigured(currentAggregate, nextAggregate);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: sp1VerifierGateway,
            data: abi.encodeCall(ISP1VerifierGatewayView.addRoute, (sp1VerifierRouteEnv)),
            value: 0
        });

        calls[1] = Call({
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

        _assertGatewayConfigured();
        _assertZkVerifierConfigured(currentAggregate, nextZkVerifier);
        _assertAggregateVerifierConfigured(currentAggregate, nextAggregate);
    }

    function _assertGatewayReadyForRouteAdd() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        (address verifier, bool frozen) = gateway.routes(sp1VerifierSelector);

        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
        require(verifier == address(0), "sp1 gateway route already set");
        require(!frozen, "sp1 gateway route unexpectedly frozen");
    }

    function _assertGatewayConfigured() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        (address verifier, bool frozen) = gateway.routes(sp1VerifierSelector);

        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
        require(verifier == sp1VerifierRouteEnv, "sp1 gateway route mismatch");
        require(!frozen, "sp1 gateway route frozen");
    }

    function _assertZkVerifierConfigured(AggregateVerifier currentAggregate, address zkVerifier) internal view {
        require(
            address(ZkVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == address(currentAggregate.anchorStateRegistry()),
            "zk verifier asr mismatch"
        );
        require(address(ZkVerifier(zkVerifier).SP1_VERIFIER()) == sp1VerifierGateway, "zk verifier sp1 mismatch");
    }

    function _assertAggregateVerifierConfigured(AggregateVerifier currentAggregate, AggregateVerifier nextAggregate)
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
        require(address(nextAggregate.ZK_VERIFIER()) == nextZkVerifier, "next aggregate zk verifier mismatch");
        require(nextAggregate.TEE_IMAGE_HASH() == currentAggregate.TEE_IMAGE_HASH(), "next aggregate tee hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == currentAggregate.ZK_RANGE_HASH(), "next aggregate range hash mismatch");
        require(
            nextAggregate.ZK_AGGREGATE_HASH() == currentAggregate.ZK_AGGREGATE_HASH(),
            "next aggregate aggregate hash mismatch"
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
