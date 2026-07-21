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

interface IZkVerifierView {
    function SP1_VERIFIER() external view returns (address);
}

interface ISP1VerifierGatewayView {
    function owner() external view returns (address);
    function routes(bytes4 selector) external view returns (address verifier, bool frozen);
    function addRoute(address verifier) external;
    function freezeRoute(bytes4 selector) external;
}

interface ISP1VerifierWithHashView {
    function VERIFIER_HASH() external view returns (bytes32);
}

/// @notice Adds PLONK, freezes Groth16, and sets the new AggregateVerifier on the DGF.
contract UpgradePlonkAndVerifierHashes is MultisigScript {
    bytes4 internal constant GROTH16_SELECTOR = bytes4(0x4388a21c);

    address internal immutable ownerSafeEnv;
    address internal immutable disputeGameFactoryProxyEnv;
    GameType internal immutable gameTypeEnv;
    address internal immutable sp1VerifierRouteEnv;
    bytes32 internal immutable zkRangeHashEnv;
    bytes32 internal immutable zkAggregateHashEnv;

    address internal immutable currentAggregateVerifier;
    address internal immutable sp1VerifierGateway;
    bytes4 internal immutable plonkSelector;
    address internal immutable nextAggregateVerifier;

    constructor() {
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);
        sp1VerifierGateway = IZkVerifierView(address(AggregateVerifier(currentAggregateVerifier).ZK_VERIFIER()))
            .SP1_VERIFIER();
        plonkSelector = bytes4(ISP1VerifierWithHashView(sp1VerifierRouteEnv).VERIFIER_HASH());

        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/addresses.json"));
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});
    }

    function setUp() public view {
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(nextAggregateVerifier != address(0) && nextAggregateVerifier != currentAggregateVerifier, "bad next av");
        require(sp1VerifierRouteEnv != address(0), "sp1 route not set");
        require(zkRangeHashEnv != bytes32(0) && zkAggregateHashEnv != bytes32(0), "zk hashes not set");

        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier next = AggregateVerifier(nextAggregateVerifier);
        require(GameType.unwrap(current.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch");
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(gameTypeEnv), "next game type mismatch");

        _assertGatewayReady();
        _assertHashes(current, next);
        _assertContinuity(current, next);
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](3);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: sp1VerifierGateway,
            data: abi.encodeCall(ISP1VerifierGatewayView.addRoute, (sp1VerifierRouteEnv)),
            value: 0
        });
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: sp1VerifierGateway,
            data: abi.encodeCall(ISP1VerifierGatewayView.freezeRoute, (GROTH16_SELECTOR)),
            value: 0
        });
        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (gameTypeEnv, nextAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        AggregateVerifier current = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier next = AggregateVerifier(nextAggregateVerifier);

        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv) == nextAggregateVerifier,
            "dgf mismatch"
        );
        _assertGatewayConfigured();
        _assertHashes(current, next);
        _assertContinuity(current, next);
    }

    function _assertGatewayReady() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        (address plonk,) = gateway.routes(plonkSelector);
        (address groth16, bool groth16Frozen) = gateway.routes(GROTH16_SELECTOR);

        require(gateway.owner() == ownerSafeEnv, "gateway owner mismatch");
        require(plonk == address(0), "plonk route already set");
        require(groth16 != address(0) && !groth16Frozen, "groth16 not ready to freeze");
    }

    function _assertGatewayConfigured() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        (address plonk, bool plonkFrozen) = gateway.routes(plonkSelector);
        (, bool groth16Frozen) = gateway.routes(GROTH16_SELECTOR);

        require(plonk == sp1VerifierRouteEnv && !plonkFrozen, "plonk route misconfigured");
        require(groth16Frozen, "groth16 not frozen");
    }

    function _assertHashes(AggregateVerifier current, AggregateVerifier next) internal view {
        require(next.TEE_IMAGE_HASH() == current.TEE_IMAGE_HASH(), "tee hash changed");
        require(next.ZK_RANGE_HASH() == zkRangeHashEnv, "zk range hash mismatch");
        require(next.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "zk aggregate hash mismatch");
    }

    function _assertContinuity(AggregateVerifier current, AggregateVerifier next) internal view {
        require(GameType.unwrap(next.gameType()) == GameType.unwrap(current.gameType()), "game type mismatch");
        require(
            address(next.anchorStateRegistry()) == address(current.anchorStateRegistry()), "asr mismatch"
        );
        require(
            address(next.DISPUTE_GAME_FACTORY()) == address(current.DISPUTE_GAME_FACTORY()), "dgf mismatch"
        );
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
