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

/// @notice Deploys a new AggregateVerifier that uses the PROXY_ADMIN_OWNER-owned SP1 gateway.
contract DeployAggregateVerifier is Script {
    // Task config from .env.
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal ownerSafeEnv;
    address internal sp1VerifierRouteEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;

    // Constructor args copied from the live AggregateVerifier.
    GameType internal currentGameType;
    IAnchorStateRegistry internal currentAnchorStateRegistry;
    IDelayedWETH internal currentDelayedWeth;
    address internal currentTeeVerifier;
    address internal currentZkVerifier;
    bytes32 internal currentTeeImageHash;
    bytes32 internal currentZkRangeHash;
    bytes32 internal currentZkAggregateHash;
    bytes32 internal currentConfigHash;
    uint256 internal currentL2ChainId;
    uint256 internal currentBlockInterval;
    uint256 internal currentIntermediateBlockInterval;

    // Deployment inputs produced by earlier EOA scripts and read from addresses.json.
    address internal sp1VerifierGateway;
    address internal nextZkVerifier;

    // Derived route metadata.
    bytes4 internal sp1VerifierSelector;

    // Deployment output written to addresses.json.
    address public aggregateVerifier;

    function setUp() public {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        currentGameType = currentAggregate.gameType();
        currentAnchorStateRegistry = currentAggregate.anchorStateRegistry();
        currentDelayedWeth = currentAggregate.DELAYED_WETH();
        currentTeeVerifier = address(currentAggregate.TEE_VERIFIER());
        currentZkVerifier = address(currentAggregate.ZK_VERIFIER());
        currentTeeImageHash = currentAggregate.TEE_IMAGE_HASH();
        currentZkRangeHash = currentAggregate.ZK_RANGE_HASH();
        currentZkAggregateHash = currentAggregate.ZK_AGGREGATE_HASH();
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

        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(GameType.unwrap(currentGameType) == GameType.unwrap(gameTypeEnv), "current game type mismatch");
        require(currentTeeVerifier != address(0), "current tee verifier not found");
        require(currentZkVerifier != address(0), "current zk verifier not found");
        require(sp1VerifierGateway != address(0), "sp1 verifier gateway not set");
        require(nextZkVerifier != address(0), "next zk verifier not set");
        require(nextZkVerifier != currentZkVerifier, "next zk verifier equals current");

        _assertGatewayOwner();
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
                teeImageHash: currentTeeImageHash,
                zkHashes: AggregateVerifier.ZkHashes({
                    rangeHash: currentZkRangeHash, aggregateHash: currentZkAggregateHash
                }),
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
        _assertGatewayOwner();
        _assertZkVerifierConfigured(nextZkVerifier);
        _assertAggregateVerifierConfigured(AggregateVerifier(aggregateVerifier));
    }

    function _assertGatewayOwner() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
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
        require(av.TEE_IMAGE_HASH() == currentTeeImageHash, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == currentZkRangeHash, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == currentZkAggregateHash, "aggregate zk aggregate hash mismatch");
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
