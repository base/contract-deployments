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
import {GameTypes, Duration, Claim, LibClaim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

/// @notice This script deploys new versions of FaultDisputeGame and PermissionedDisputeGame with all the same
///         parameters as the existing implementations excluding the absolute prestate.
contract DeployDisputeGames is Script {
    using Strings for address;
    using LibClaim for Claim;

    SystemConfig internal _SYSTEM_CONFIG = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));
    Claim immutable absolutePrestate;

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

    constructor() {
        absolutePrestate = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));
    }

    function setUp() public {
        dgfProxy = DisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGame currentFdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame currentPdg =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

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

    function _postCheck(address fdg, address pdg) private view {
        require(FaultDisputeGame(fdg).absolutePrestate().raw() == vm.envBytes32("ABSOLUTE_PRESTATE"), "Postcheck 1");
        require(
            PermissionedDisputeGame(pdg).absolutePrestate().raw() == vm.envBytes32("ABSOLUTE_PRESTATE"), "Postcheck 2"
        );
    }

    function run() public {
        console.log("FDG Args:");
        console.logBytes(
            abi.encode(
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

        console.log("PDG Args:");
        console.logBytes(
            abi.encode(
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
