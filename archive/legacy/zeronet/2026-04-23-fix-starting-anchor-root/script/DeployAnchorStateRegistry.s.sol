// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";

/// @notice Deploys the next AnchorStateRegistry implementation used to correct the starting anchor root.
contract DeployAnchorStateRegistry is Script {
    address internal anchorStateRegistryProxyEnv;

    uint256 internal currentDisputeGameFinalityDelaySeconds;
    uint8 internal currentInitVersion;

    address public anchorStateRegistryImpl;

    function setUp() public {
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        require(anchorStateRegistryProxyEnv != address(0), "anchor state registry proxy not found");

        AnchorStateRegistry currentAsr = AnchorStateRegistry(anchorStateRegistryProxyEnv);
        currentDisputeGameFinalityDelaySeconds = currentAsr.disputeGameFinalityDelaySeconds();
        currentInitVersion = currentAsr.initVersion();
    }

    function run() external {
        vm.startBroadcast();

        anchorStateRegistryImpl = address(
            new AnchorStateRegistry({_disputeGameFinalityDelaySeconds: currentDisputeGameFinalityDelaySeconds})
        );

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        AnchorStateRegistry nextAsr = AnchorStateRegistry(anchorStateRegistryImpl);

        require(
            nextAsr.disputeGameFinalityDelaySeconds() == currentDisputeGameFinalityDelaySeconds,
            "anchor state registry finality delay mismatch"
        );
        require(nextAsr.initVersion() == currentInitVersion + 1, "anchor state registry init version mismatch");
    }

    function _writeAddresses() internal {
        console.log("AnchorStateRegistry impl:", anchorStateRegistryImpl);

        string memory root = "root";
        string memory json =
            vm.serializeAddress({objectKey: root, valueKey: "anchorStateRegistryImpl", value: anchorStateRegistryImpl});
        vm.writeJson({json: json, path: "addresses.json"});
    }
}
