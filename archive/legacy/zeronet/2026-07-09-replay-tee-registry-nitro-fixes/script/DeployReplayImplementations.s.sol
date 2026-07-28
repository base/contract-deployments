// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {INitroEnclaveVerifier} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {MockVerifier} from "@base-contracts/src/multiproof/mocks/MockVerifier.sol";

contract DeployReplayImplementations is Script {
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal immutable EXISTING_AGGREGATE_VERIFIER_ENV = vm.envAddress("EXISTING_AGGREGATE_VERIFIER");
    bytes32 internal immutable CURRENT_TEE_IMAGE_HASH_ENV = vm.envBytes32("CURRENT_TEE_IMAGE_HASH");
    bytes32 internal immutable NEW_TEE_IMAGE_HASH_ENV = vm.envBytes32("TEE_IMAGE_HASH");

    address internal nitroEnclaveVerifier;

    GameType internal gameType;
    IAnchorStateRegistry internal anchorStateRegistry;
    IDelayedWETH internal delayedWeth;
    address internal teeVerifier;
    address internal zkVerifier;
    bytes32 internal zkRangeHash;
    bytes32 internal zkAggregateHash;
    bytes32 internal configHash;
    uint256 internal l2ChainId;
    uint256 internal blockInterval;
    uint256 internal intermediateBlockInterval;
    uint256 internal proofThreshold;

    address public teeProverRegistryImpl;
    address public aggregateVerifier;

    function setUp() public {
        require(CURRENT_TEE_IMAGE_HASH_ENV != NEW_TEE_IMAGE_HASH_ENV, "tee image hash already target");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        nitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});

        AggregateVerifier existing = AggregateVerifier(EXISTING_AGGREGATE_VERIFIER_ENV);
        require(existing.TEE_IMAGE_HASH() == CURRENT_TEE_IMAGE_HASH_ENV, "unexpected current tee image hash");

        gameType = existing.gameType();
        anchorStateRegistry = existing.anchorStateRegistry();
        delayedWeth = existing.DELAYED_WETH();
        teeVerifier = address(existing.TEE_VERIFIER());
        zkVerifier = address(existing.ZK_VERIFIER());
        zkRangeHash = existing.ZK_RANGE_HASH();
        zkAggregateHash = existing.ZK_AGGREGATE_HASH();
        configHash = existing.CONFIG_HASH();
        l2ChainId = existing.L2_CHAIN_ID();
        blockInterval = existing.BLOCK_INTERVAL();
        intermediateBlockInterval = existing.INTERMEDIATE_BLOCK_INTERVAL();
        proofThreshold = existing.PROOF_THRESHOLD();
    }

    function run() external {
        vm.startBroadcast();

        teeProverRegistryImpl = address(
            new TEEProverRegistry({
                nitroVerifier: INitroEnclaveVerifier(nitroEnclaveVerifier),
                factory: IDisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY_ENV)
            })
        );

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: gameType,
                anchorStateRegistry_: anchorStateRegistry,
                delayedWETH: delayedWeth,
                teeVerifier: TEEVerifier(teeVerifier),
                zkVerifier: MockVerifier(zkVerifier),
                teeImageHash: NEW_TEE_IMAGE_HASH_ENV,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHash, aggregateHash: zkAggregateHash}),
                configHash: configHash,
                l2ChainId: l2ChainId,
                blockInterval: blockInterval,
                intermediateBlockInterval: intermediateBlockInterval,
                proofThreshold: proofThreshold
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        TEEProverRegistry registry = TEEProverRegistry(teeProverRegistryImpl);
        require(address(registry.NITRO_VERIFIER()) == nitroEnclaveVerifier, "tee registry nitro mismatch");
        require(address(registry.DISPUTE_GAME_FACTORY()) == DISPUTE_GAME_FACTORY_PROXY_ENV, "tee registry dgf mismatch");

        AggregateVerifier av = AggregateVerifier(aggregateVerifier);
        require(GameType.unwrap(av.gameType()) == GameType.unwrap(gameType), "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == address(anchorStateRegistry), "aggregate asr mismatch");
        require(
            address(av.DISPUTE_GAME_FACTORY()) == address(anchorStateRegistry.disputeGameFactory()),
            "aggregate dgf mismatch"
        );
        require(address(av.DELAYED_WETH()) == address(delayedWeth), "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == teeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == zkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == NEW_TEE_IMAGE_HASH_ENV, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == configHash, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainId, "aggregate l2 chain id mismatch");
        require(av.BLOCK_INTERVAL() == blockInterval, "aggregate block interval mismatch");
        require(
            av.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockInterval, "aggregate intermediate interval mismatch"
        );
        require(av.PROOF_THRESHOLD() == proofThreshold, "aggregate proof threshold mismatch");
    }

    function _writeAddresses() internal {
        console.log("TEEProverRegistryImpl:", teeProverRegistryImpl);
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "nitroEnclaveVerifier", value: nitroEnclaveVerifier});
        json = vm.serializeAddress({objectKey: root, valueKey: "teeProverRegistryImpl", value: teeProverRegistryImpl});
        json = vm.serializeAddress({objectKey: root, valueKey: "aggregateVerifier", value: aggregateVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
