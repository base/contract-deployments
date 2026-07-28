// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {IVerifier} from "interfaces/multiproof/IVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

interface ISP1VerifierGatewayView {
    function owner() external view returns (address);
    function routes(bytes4 selector) external view returns (address verifier, bool frozen);
}

interface ISP1VerifierWithHashView {
    function VERIFIER_HASH() external view returns (bytes32);
}

/// @notice Deploys the final replay AggregateVerifier for the May task aggregate.
contract DeployAggregateVerifier is Script {
    address internal immutable disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    GameType internal immutable gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
    address internal immutable ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");
    bytes32 internal immutable teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
    bytes32 internal immutable zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
    bytes32 internal immutable zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");

    address internal currentAggregateVerifier;

    GameType internal currentGameType;
    IAnchorStateRegistry internal currentAnchorStateRegistry;
    IDelayedWETH internal currentDelayedWeth;
    address internal currentTeeVerifier;
    bytes32 internal currentConfigHash;
    uint256 internal currentL2ChainId;
    uint256 internal currentBlockInterval;
    uint256 internal currentIntermediateBlockInterval;

    address internal sp1VerifierGateway;
    address internal nextZkVerifier;
    bytes4 internal sp1VerifierSelector;

    address public aggregateVerifier;

    function setUp() public {
        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        currentGameType = currentAggregate.gameType();
        currentAnchorStateRegistry = currentAggregate.anchorStateRegistry();
        currentDelayedWeth = currentAggregate.DELAYED_WETH();
        currentTeeVerifier = address(currentAggregate.TEE_VERIFIER());
        currentConfigHash = currentAggregate.CONFIG_HASH();
        currentL2ChainId = currentAggregate.L2_CHAIN_ID();
        currentBlockInterval = currentAggregate.BLOCK_INTERVAL();
        currentIntermediateBlockInterval = currentAggregate.INTERMEDIATE_BLOCK_INTERVAL();

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        sp1VerifierGateway = vm.parseJsonAddress({json: json, key: ".sp1VerifierGateway"});
        nextZkVerifier = vm.parseJsonAddress({json: json, key: ".zkVerifier"});

        sp1VerifierSelector = bytes4(ISP1VerifierWithHashView(sp1VerifierRouteEnv).VERIFIER_HASH());

        require(GameType.unwrap(currentGameType) == GameType.unwrap(gameTypeEnv), "current game type mismatch");
        require(currentTeeVerifier != address(0), "current tee verifier not found");
        require(teeImageHashEnv != bytes32(0), "tee image hash not set");
        require(zkRangeHashEnv != bytes32(0), "zk range hash not set");
        require(zkAggregateHashEnv != bytes32(0), "zk aggregate hash not set");
        require(sp1VerifierGateway != address(0), "sp1 verifier gateway not set");
        require(nextZkVerifier != address(0), "next zk verifier not set");

        _assertGatewayReadyForRouteAdd();
        _assertZkVerifierConfigured(nextZkVerifier);
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: currentGameType,
                anchorStateRegistry_: currentAnchorStateRegistry,
                delayedWETH: currentDelayedWeth,
                teeVerifier: IVerifier(currentTeeVerifier),
                zkVerifier: IVerifier(nextZkVerifier),
                teeImageHash: teeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: currentConfigHash,
                l2ChainId: currentL2ChainId,
                blockInterval: currentBlockInterval,
                intermediateBlockInterval: currentIntermediateBlockInterval
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _assertGatewayReadyForRouteAdd();
        _assertZkVerifierConfigured(nextZkVerifier);
        _assertAggregateVerifierConfigured(AggregateVerifier(aggregateVerifier));
    }

    function _assertGatewayReadyForRouteAdd() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        (address verifier, bool frozen) = gateway.routes(sp1VerifierSelector);

        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
        require(verifier == address(0), "sp1 gateway route already set");
        require(!frozen, "sp1 gateway route unexpectedly frozen");
    }

    function _assertZkVerifierConfigured(address zkVerifier) internal view {
        require(
            address(ZkVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == address(currentAnchorStateRegistry),
            "zk verifier asr mismatch"
        );
        require(address(ZkVerifier(zkVerifier).SP1_VERIFIER()) == sp1VerifierGateway, "zk verifier sp1 mismatch");
    }

    function _assertAggregateVerifierConfigured(AggregateVerifier av) internal view {
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);

        require(GameType.unwrap(av.gameType()) == GameType.unwrap(currentGameType), "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == address(currentAnchorStateRegistry), "aggregate asr mismatch");
        require(
            address(av.DISPUTE_GAME_FACTORY()) == address(currentAggregate.DISPUTE_GAME_FACTORY()),
            "aggregate dgf mismatch"
        );
        require(address(av.DELAYED_WETH()) == address(currentDelayedWeth), "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == currentTeeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == nextZkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == currentConfigHash, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == currentL2ChainId, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == currentBlockInterval, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == currentIntermediateBlockInterval,
            "aggregate intermediate interval mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);
        vm.writeJson({json: vm.toString(aggregateVerifier), path: "addresses.json", valueKey: ".aggregateVerifier"});
    }
}
