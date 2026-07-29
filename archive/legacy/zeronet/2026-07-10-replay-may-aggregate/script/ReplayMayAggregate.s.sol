// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";
import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgrade(address proxy, address implementation) external;
}

interface IProxy {
    function implementation() external view returns (address);
}

interface ISystemConfigParams {
    function owner() external view returns (address);
    function eip1559Elasticity() external view returns (uint32);
    function eip1559Denominator() external view returns (uint32);
    function setEIP1559Params(uint32 denominator, uint32 elasticity) external;
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 gasLimit) external;
    function daFootprintGasScalar() external view returns (uint16);
    function setDAFootprintGasScalar(uint16 daFootprintGasScalar) external;
}

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

/// @notice Replays the May 2026 Zeronet task aggregate that shared the same base-contracts commit.
contract ReplayMayAggregate is MultisigScript {
    address internal immutable ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable proxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
    address internal immutable systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
    address internal immutable anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
    address internal immutable disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    GameType internal immutable gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
    address internal immutable sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");
    bytes32 internal immutable teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
    bytes32 internal immutable zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
    bytes32 internal immutable zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
    uint64 internal immutable fromGasLimitEnv = uint64(vm.envUint("FROM_GAS_LIMIT"));
    uint64 internal immutable toGasLimitEnv = uint64(vm.envUint("TO_GAS_LIMIT"));
    uint32 internal immutable fromElasticityEnv = uint32(vm.envUint("FROM_ELASTICITY"));
    uint32 internal immutable toElasticityEnv = uint32(vm.envUint("TO_ELASTICITY"));
    uint32 internal immutable fromDenominatorEnv = uint32(vm.envUint("FROM_DENOMINATOR"));
    uint32 internal immutable toDenominatorEnv = uint32(vm.envUint("TO_DENOMINATOR"));
    uint16 internal immutable fromDaFootprintGasScalarEnv = uint16(vm.envUint("FROM_DA_FOOTPRINT_GAS_SCALAR"));
    uint16 internal immutable toDaFootprintGasScalarEnv = uint16(vm.envUint("TO_DA_FOOTPRINT_GAS_SCALAR"));

    address internal currentAggregateVerifier;
    address internal currentSystemConfigImpl;
    address internal nextSystemConfigImpl;
    address internal sp1VerifierGateway;
    address internal nextZkVerifier;
    address internal nextAggregateVerifier;
    GameType internal nextGameType;
    bytes4 internal sp1VerifierSelector;

    function setUp() public {
        require(IProxyAdmin(proxyAdminEnv).owner() == ownerSafeEnv, "proxy admin owner mismatch");
        require(ISystemConfigParams(systemConfigEnv).owner() == ownerSafeEnv, "system config owner mismatch");
        require(IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).owner() == ownerSafeEnv, "dgf owner mismatch");

        vm.prank(proxyAdminEnv);
        currentSystemConfigImpl = IProxy(systemConfigEnv).implementation();
        _assertCurrentGasParams();

        currentAggregateVerifier = IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv);
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        require(
            address(currentAggregate.anchorStateRegistry()) == anchorStateRegistryProxyEnv,
            "current aggregate asr mismatch"
        );

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);

        nextSystemConfigImpl = vm.parseJsonAddress({json: json, key: ".systemConfig"});
        sp1VerifierGateway = vm.parseJsonAddress({json: json, key: ".sp1VerifierGateway"});
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});
        nextAggregateVerifier = vm.parseJsonAddress({json: json, key: ".aggregateVerifier"});

        nextGameType = AggregateVerifier(nextAggregateVerifier).gameType();
        sp1VerifierSelector = bytes4(ISP1VerifierWithHashView(sp1VerifierRouteEnv).VERIFIER_HASH());

        require(nextSystemConfigImpl != address(0), "next system config impl not set");
        require(nextSystemConfigImpl != currentSystemConfigImpl, "next system config impl equals current");
        require(sp1VerifierGateway != address(0), "sp1 verifier gateway not set");
        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(nextAggregateVerifier != address(0), "next aggregate verifier not set");
        require(nextAggregateVerifier != currentAggregateVerifier, "next aggregate verifier equals current");
        require(sp1VerifierRouteEnv != address(0), "sp1 verifier route not set");
        require(sp1VerifierSelector != bytes4(0), "sp1 verifier selector not set");
        _assertSystemConfigImpl(nextSystemConfigImpl);
        _assertGatewayReadyForRouteAdd();
        _assertZkVerifierConfigured(currentAggregate, nextZkVerifier);
        _assertAggregateVerifierConfigured(currentAggregate, AggregateVerifier(nextAggregateVerifier));
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](6);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdminEnv,
            data: abi.encodeCall(IProxyAdmin.upgrade, (systemConfigEnv, nextSystemConfigImpl)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: systemConfigEnv,
            data: abi.encodeCall(ISystemConfigParams.setEIP1559Params, (toDenominatorEnv, toElasticityEnv)),
            value: 0
        });

        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: systemConfigEnv,
            data: abi.encodeCall(ISystemConfigParams.setGasLimit, (toGasLimitEnv)),
            value: 0
        });

        calls[3] = Call({
            operation: Enum.Operation.Call,
            target: systemConfigEnv,
            data: abi.encodeCall(ISystemConfigParams.setDAFootprintGasScalar, (toDaFootprintGasScalarEnv)),
            value: 0
        });

        calls[4] = Call({
            operation: Enum.Operation.Call,
            target: sp1VerifierGateway,
            data: abi.encodeCall(ISP1VerifierGatewayView.addRoute, (sp1VerifierRouteEnv)),
            value: 0
        });

        calls[5] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactoryProxyEnv,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (nextGameType, nextAggregateVerifier, "")),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        AggregateVerifier nextAggregate = AggregateVerifier(nextAggregateVerifier);
        vm.prank(proxyAdminEnv);
        require(IProxy(systemConfigEnv).implementation() == nextSystemConfigImpl, "system config impl mismatch");
        _assertSystemConfigImpl(nextSystemConfigImpl);
        _assertUpdatedGasParams();

        require(
            IDisputeGameFactoryAdmin(disputeGameFactoryProxyEnv).gameImpls(nextGameType) == nextAggregateVerifier,
            "dgf aggregate verifier mismatch"
        );

        _assertGatewayConfigured();
        _assertZkVerifierConfigured(currentAggregate, nextZkVerifier);
        _assertAggregateVerifierConfigured(currentAggregate, nextAggregate);
    }

    function _assertCurrentGasParams() internal view {
        ISystemConfigParams cfg = ISystemConfigParams(systemConfigEnv);
        require(cfg.gasLimit() == fromGasLimitEnv, "current gas limit mismatch");
        require(cfg.eip1559Elasticity() == fromElasticityEnv, "current elasticity mismatch");
        require(cfg.eip1559Denominator() == fromDenominatorEnv, "current denominator mismatch");
        require(cfg.daFootprintGasScalar() == fromDaFootprintGasScalarEnv, "current da scalar mismatch");
    }

    function _assertUpdatedGasParams() internal view {
        ISystemConfigParams cfg = ISystemConfigParams(systemConfigEnv);
        require(cfg.gasLimit() == toGasLimitEnv, "gas limit mismatch");
        require(cfg.eip1559Elasticity() == toElasticityEnv, "elasticity mismatch");
        require(cfg.eip1559Denominator() == toDenominatorEnv, "denominator mismatch");
        require(cfg.daFootprintGasScalar() == toDaFootprintGasScalarEnv, "da scalar mismatch");
    }

    function _assertSystemConfigImpl(address impl) internal view {
        require(
            keccak256(bytes(SystemConfig(impl).version())) == keccak256("3.13.2+max-gas-limit-2000M"),
            "system config version mismatch"
        );
        require(SystemConfig(impl).maximumGasLimit() == 2_000_000_000, "system config max gas mismatch");
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
        require(GameType.unwrap(nextGameType) == GameType.unwrap(gameTypeEnv), "next game type mismatch");
        require(nextAggregate.TEE_IMAGE_HASH() == teeImageHashEnv, "next aggregate tee image hash mismatch");
        require(nextAggregate.ZK_RANGE_HASH() == zkRangeHashEnv, "next aggregate zk range hash mismatch");
        require(nextAggregate.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "next aggregate zk aggregate hash mismatch");
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
