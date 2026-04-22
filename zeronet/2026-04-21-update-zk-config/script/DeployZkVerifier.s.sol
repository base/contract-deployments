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
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal sp1VerifierEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;

    // Constructor args copied from the live AggregateVerifier.
    address internal currentAnchorStateRegistry;

    // Deployment output written to addresses.json.
    address public zkVerifier;

    function setUp() public {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        sp1VerifierEnv = vm.envAddress("SP1_VERIFIER");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));
        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");

        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        require(
            GameType.unwrap(currentAggregate.gameType()) == GameType.unwrap(gameTypeEnv), "current game type mismatch"
        );
        currentAnchorStateRegistry = address(currentAggregate.anchorStateRegistry());

        require(currentAnchorStateRegistry != address(0), "anchor state registry not found");
        require(sp1VerifierEnv != address(0), "sp1 verifier not set");
    }

    function run() external {
        vm.startBroadcast();

        zkVerifier = address(
            new ZkVerifier({
                sp1Verifier: ISP1Verifier(sp1VerifierEnv),
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
        require(address(ZkVerifier(zkVerifier).SP1_VERIFIER()) == sp1VerifierEnv, "zk verifier sp1 verifier mismatch");
    }

    function _writeAddresses() internal {
        console.log("ZKVerifier:", zkVerifier);

        string memory root = "root";
        string memory json = vm.serializeAddress({objectKey: root, valueKey: "zkVerifier", value: zkVerifier});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
