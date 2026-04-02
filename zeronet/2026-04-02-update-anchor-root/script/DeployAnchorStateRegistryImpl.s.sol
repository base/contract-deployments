// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";

/// @title DeployAnchorStateRegistryImpl
/// @notice Deploys a new AnchorStateRegistry implementation with reinitializer version 3.
///         The patched source bumps ReinitializableBase(2) -> ReinitializableBase(3) and
///         resets anchorGame = address(0) inside initialize(), allowing a fresh anchor root
///         to take effect via a subsequent upgradeAndCall.
contract DeployAnchorStateRegistryImpl is Script {
    uint256 internal disputeGameFinalityDelaySecondsEnv;

    function setUp() public {
        disputeGameFinalityDelaySecondsEnv = vm.envUint("DISPUTE_GAME_FINALITY_DELAY_SECONDS");
    }

    function run() external {
        vm.startBroadcast();

        address anchorStateRegistryImpl =
            address(new AnchorStateRegistry({_disputeGameFinalityDelaySeconds: disputeGameFinalityDelaySecondsEnv}));

        vm.stopBroadcast();

        // Post-check: validate immutables.
        require(
            AnchorStateRegistry(anchorStateRegistryImpl).disputeGameFinalityDelaySeconds()
                == disputeGameFinalityDelaySecondsEnv,
            "asr finality delay mismatch"
        );
        require(AnchorStateRegistry(anchorStateRegistryImpl).initVersion() == 3, "asr init version must be 3");

        console.log("AnchorStateRegistry impl:", anchorStateRegistryImpl);

        vm.writeJson({json: vm.toString(anchorStateRegistryImpl), path: "addresses.json", valueKey: ".anchorStateRegistryImpl"});
    }
}
