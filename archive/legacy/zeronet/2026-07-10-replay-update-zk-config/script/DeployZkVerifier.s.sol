// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {ISP1Verifier} from "src/dispute/zk/ISP1Verifier.sol";
import {ZkVerifier} from "@base-contracts/src/multiproof/zk/ZKVerifier.sol";

/// @notice Deploys the ZK verifier used by the multiproof AggregateVerifier.
contract DeployZkVerifier is Script {
    // Task config from .env.
    address internal immutable DISPUTE_GAME_FACTORY_PROXY_ENV = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    GameType internal immutable GAME_TYPE_ENV = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
    address internal immutable SP1_VERIFIER_ENV = vm.envAddress("SP1_VERIFIER");

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;

    // Constructor args copied from the live AggregateVerifier.
    address internal currentAnchorStateRegistry;

    // Deployment output written to addresses.json.
    address public zkVerifier;

    function setUp() public {
        currentAggregateVerifier = address(IDisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY_ENV).gameImpls(GAME_TYPE_ENV));
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(GAME_TYPE_ENV), "current game type mismatch"
        );
        currentAnchorStateRegistry = address(currentAggregate.anchorStateRegistry());

        require(currentAnchorStateRegistry != address(0), "anchor state registry not found");
        require(SP1_VERIFIER_ENV != address(0), "sp1 verifier not set");
    }

    function run() external {
        vm.startBroadcast();

        zkVerifier = address(
            new ZkVerifier({
                sp1Verifier: ISP1Verifier(SP1_VERIFIER_ENV),
                anchorStateRegistry: IAnchorStateRegistry(currentAnchorStateRegistry)
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(
            address(ZkVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == currentAnchorStateRegistry,
            "zk verifier asr mismatch"
        );
        require(address(ZkVerifier(zkVerifier).SP1_VERIFIER()) == SP1_VERIFIER_ENV, "zk verifier sp1 verifier mismatch");
    }

    function _writeAddresses() internal {
        console.log("ZKVerifier:", zkVerifier);

        string memory root = "root";
        string memory json = vm.serializeAddress({objectKey: root, valueKey: "zkVerifier", value: zkVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
