// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {
    FaultDisputeGame,
    IAnchorStateRegistry,
    IDelayedWETH,
    IBigStepper
} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {GameTypes, GameType, Duration, Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract DeployHoloceneContracts is Script {
    GameType faultDisputeGameContractGameType = GameTypes.CANNON;
    GameType permissionedDisputeGameContractGameType = GameTypes.PERMISSIONED_CANNON;

    uint256 maxGameDepth = vm.envUint("MAX_GAME_DEPTH");
    uint256 splitDepth = vm.envUint("SPLIT_DEPTH");
    uint256 l2ChainId = vm.envUint("L2_CHAIN_ID");

    address proposer = vm.envAddress("PROPOSER_ADDRESS");
    address challenger = vm.envAddress("CHALLENGER_ADDRESS");

    Duration clockExtension = Duration.wrap(uint64(vm.envUint("CLOCK_EXTENSION")));
    Duration maxClockDuration = Duration.wrap(uint64(vm.envUint("MAX_CLOCK_DURATION")));
    Claim absolutePrestate = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));

    IDelayedWETH faultDisputeGameWeth = IDelayedWETH(payable(vm.envAddress("WETH_ADDRESS")));
    IDelayedWETH permissionedDisputeGameWeth = IDelayedWETH(payable(vm.envAddress("PERMISSIONED_WETH_ADDRESS")));

    IAnchorStateRegistry anchorStateRegistry =
        IAnchorStateRegistry(payable(vm.envAddress("ANCHOR_STATE_REGISTRY_ADDRESS")));
    IBigStepper bigStepper = IBigStepper(payable(vm.envAddress("VM_ADDRESS")));

    function run() public {
        vm.startBroadcast();
        new FaultDisputeGame(
            faultDisputeGameContractGameType,
            absolutePrestate,
            maxGameDepth,
            splitDepth,
            clockExtension,
            maxClockDuration,
            bigStepper,
            faultDisputeGameWeth,
            anchorStateRegistry,
            l2ChainId
        );

        new PermissionedDisputeGame(
            permissionedDisputeGameContractGameType,
            absolutePrestate,
            maxGameDepth,
            splitDepth,
            clockExtension,
            maxClockDuration,
            bigStepper,
            permissionedDisputeGameWeth,
            anchorStateRegistry,
            l2ChainId,
            proposer,
            challenger
        );
        vm.stopBroadcast();
    }
}
