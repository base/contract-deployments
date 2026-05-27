// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IVerifier} from "interfaces/multiproof/IVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

/// @notice Deploys a single new AggregateVerifier implementation that reuses the
///         existing multiproof stack (DelayedWETH, TEEVerifier, ZKVerifier,
///         AnchorStateRegistry) from `mainnet/2026-05-21-activate-multiproof`.
///         Only `TEE_IMAGE_HASH`, `ZK_RANGE_HASH`, and `ZK_AGGREGATE_HASH`
///         change between the old and new implementation.
contract DeployAggregateVerifier is Script {
    // Existing L1 dependencies — reused unchanged.
    address internal anchorStateRegistryProxyEnv;
    address internal delayedWethProxyEnv;
    address internal teeVerifierEnv;
    address internal zkVerifierEnv;
    address internal disputeGameFactoryProxyEnv;

    // Multiproof identity and chain-level parameters.
    uint32 internal gameTypeEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;
    bytes32 internal configHashEnv;
    uint256 internal l2ChainIdEnv;
    uint256 internal blockIntervalEnv;
    uint256 internal intermediateBlockIntervalEnv;

    // Output.
    address public aggregateVerifier;

    function setUp() public {
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        delayedWethProxyEnv = vm.envAddress("DELAYED_WETH_PROXY");
        teeVerifierEnv = vm.envAddress("TEE_VERIFIER");
        zkVerifierEnv = vm.envAddress("ZK_VERIFIER");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");
        l2ChainIdEnv = vm.envUint("L2_CHAIN_ID");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");

        _preCheckInputs();
    }

    function run() external {
        vm.startBroadcast();

        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: GameType.wrap(gameTypeEnv),
                anchorStateRegistry_: IAnchorStateRegistry(anchorStateRegistryProxyEnv),
                delayedWETH: IDelayedWETH(payable(delayedWethProxyEnv)),
                teeVerifier: TEEVerifier(teeVerifierEnv),
                zkVerifier: IVerifier(zkVerifierEnv),
                teeImageHash: teeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: configHashEnv,
                l2ChainId: l2ChainIdEnv,
                blockInterval: blockIntervalEnv,
                intermediateBlockInterval: intermediateBlockIntervalEnv
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    /// @dev Sanity checks on the wired-in stack components before deploying.
    ///      These prevent accidentally constructing the new AggregateVerifier
    ///      against the wrong stack.
    function _preCheckInputs() internal view {
        require(
            address(TEEVerifier(teeVerifierEnv).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "tee verifier asr mismatch"
        );
        require(
            address(ZkVerifier(zkVerifierEnv).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "zk verifier asr mismatch"
        );
    }

    function _postCheck() internal view {
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(GameType.unwrap(av.gameType()) == gameTypeEnv, "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "aggregate asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "aggregate dgf mismatch");
        require(address(av.DELAYED_WETH()) == delayedWethProxyEnv, "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == teeVerifierEnv, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == zkVerifierEnv, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");
        require(av.CONFIG_HASH() == configHashEnv, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainIdEnv, "aggregate l2 chain mismatch");
        require(av.BLOCK_INTERVAL() == blockIntervalEnv, "aggregate block interval mismatch");
        require(av.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockIntervalEnv, "aggregate intermediate mismatch");
    }

    function _writeAddresses() internal {
        console.log("AggregateVerifier:", aggregateVerifier);

        string memory root = "root";
        string memory json = vm.serializeAddress({objectKey: root, valueKey: "aggregateVerifier", value: aggregateVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
