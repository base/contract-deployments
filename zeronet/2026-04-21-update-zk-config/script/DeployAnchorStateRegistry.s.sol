// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";

/// @notice Deploys the next AnchorStateRegistry implementation used to reset the starting anchor root.
contract DeployAnchorStateRegistry is Script {
    // Task config from .env.
    address internal anchorStateRegistryProxyEnv;

    // Constructor args copied from the live AnchorStateRegistry proxy.
    uint256 internal currentDisputeGameFinalityDelaySeconds;
    uint8 internal currentInitVersion;

    // Deployment output written to addresses.json.
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
        vm.writeJson({
            json: vm.toString(anchorStateRegistryImpl), path: "addresses.json", valueKey: ".anchorStateRegistryImpl"
        });
    }
}
