// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {ISP1Verifier} from "src/dispute/zk/ISP1Verifier.sol";

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

/// @notice Deploys the ZK verifier used by the multiproof AggregateVerifier.
contract DeployZkVerifier is Script {
    // Task config from .env.
    address internal disputeGameFactoryProxyEnv;
    GameType internal gameTypeEnv;
    address internal ownerSafeEnv;
    address internal sp1VerifierRouteEnv;

    // Live multiproof implementation currently registered in the DGF.
    address internal currentAggregateVerifier;

    // Constructor args copied from the live AggregateVerifier.
    address internal currentAnchorStateRegistry;

    // Deployment input produced by DeploySp1Gateway and read from addresses.json.
    address internal sp1VerifierGateway;

    // Derived route metadata.
    bytes4 internal sp1VerifierSelector;

    // Deployment output written to addresses.json.
    address public zkVerifier;

    function setUp() public {
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameTypeEnv = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
        sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");

        currentAggregateVerifier = address(IDisputeGameFactory(disputeGameFactoryProxyEnv).gameImpls(gameTypeEnv));
        AggregateVerifier currentAggregate = AggregateVerifier(currentAggregateVerifier);
        currentAnchorStateRegistry = address(currentAggregate.anchorStateRegistry());

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        sp1VerifierGateway = vm.parseJsonAddress({json: json, key: ".sp1VerifierGateway"});

        sp1VerifierSelector = bytes4(ISP1VerifierWithHashView(sp1VerifierRouteEnv).VERIFIER_HASH());

        require(currentAggregateVerifier != address(0), "current aggregate verifier not found");
        require(
            GameType.unwrap(AggregateVerifier(currentAggregateVerifier).gameType()) == GameType.unwrap(gameTypeEnv),
            "current game type mismatch"
        );
        require(currentAnchorStateRegistry != address(0), "anchor state registry not found");
        require(sp1VerifierGateway != address(0), "sp1 verifier gateway not set");
        require(sp1VerifierRouteEnv != address(0), "sp1 verifier route not set");
        require(sp1VerifierSelector != bytes4(0), "sp1 verifier selector not set");

        _assertGatewayOwner();
    }

    function run() external {
        vm.startBroadcast();

        zkVerifier = address(
            new ZkVerifier({
                sp1Verifier: ISP1Verifier(sp1VerifierGateway),
                anchorStateRegistry: IAnchorStateRegistry(currentAnchorStateRegistry)
            })
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _assertGatewayOwner();
        require(
            address(ZkVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == currentAnchorStateRegistry,
            "zk verifier asr mismatch"
        );
        require(address(ZkVerifier(zkVerifier).SP1_VERIFIER()) == sp1VerifierGateway, "zk verifier sp1 mismatch");
    }

    function _assertGatewayOwner() internal view {
        ISP1VerifierGatewayView gateway = ISP1VerifierGatewayView(sp1VerifierGateway);
        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
    }

    function _writeAddresses() internal {
        console.log("ZKVerifier:", zkVerifier);

        vm.writeJson({json: vm.toString(zkVerifier), path: "addresses.json", valueKey: ".zkVerifier"});
    }
}
