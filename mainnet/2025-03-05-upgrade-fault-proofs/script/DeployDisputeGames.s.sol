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
import {GameTypes, Duration, Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice This script deploys new versions of FaultDisputeGame and PermissionedDisputeGame with all the same
///         parameters as the existing implementations excluding the absolute prestate.
contract DeployDisputeGames is Script {
    using Strings for address;

    SystemConfig internal _SYSTEM_CONFIG = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));
    Claim absolutePrestate = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));

    DisputeGameFactory dgfProxy;

    uint256 maxGameDepth;
    uint256 splitDepth;
    uint256 l2ChainId;
    address proposer;
    address challenger;
    Duration clockExtension;
    Duration maxClockDuration;
    IDelayedWETH faultDisputeGameWeth;
    IDelayedWETH permissionedDisputeGameWeth;
    IAnchorStateRegistry anchorStateRegistry;
    IBigStepper bigStepper;

    function setUp() public {
        dgfProxy = DisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGame currentFdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame currentPdg =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        absolutePrestate = currentFdg.absolutePrestate();
        maxGameDepth = currentFdg.maxGameDepth();
        splitDepth = currentFdg.splitDepth();
        clockExtension = currentFdg.clockExtension();
        maxClockDuration = currentFdg.maxClockDuration();
        bigStepper = currentFdg.vm();
        faultDisputeGameWeth = currentFdg.weth();
        anchorStateRegistry = currentFdg.anchorStateRegistry();
        l2ChainId = currentFdg.l2ChainId();

        permissionedDisputeGameWeth = currentPdg.weth();
        proposer = currentPdg.proposer();
        challenger = currentPdg.challenger();
    }

    function run() public {
        (address fdg, address pdg) = _deployContracts();

        vm.writeFile(
            "addresses.json",
            string.concat(
                "{",
                "\"faultDisputeGame\": \"",
                fdg.toHexString(),
                "\",",
                "\"permissionedDisputeGame\": \"",
                pdg.toHexString(),
                "\"" "}"
            )
        );
    }

    function _deployContracts() private returns (address, address) {
        vm.startBroadcast();
        address fdg = address(
            new FaultDisputeGame(
                GameTypes.CANNON,
                absolutePrestate,
                maxGameDepth,
                splitDepth,
                clockExtension,
                maxClockDuration,
                bigStepper,
                faultDisputeGameWeth,
                anchorStateRegistry,
                l2ChainId
            )
        );

        address pdg = address(
            new PermissionedDisputeGame(
                GameTypes.PERMISSIONED_CANNON,
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
            )
        );
        vm.stopBroadcast();

        return (fdg, pdg);
    }
}
