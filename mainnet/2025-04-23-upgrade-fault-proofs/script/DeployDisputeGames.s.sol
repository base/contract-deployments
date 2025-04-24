// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {IAnchorStateRegistry, IDelayedWETH, IBigStepper} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {
    PermissionedDisputeGame, FaultDisputeGame
} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {GameTypes, GameType, Duration, Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {LibGameType, LibDuration} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console} from "forge-std/console.sol";

/// @notice This script deploys new versions of FaultDisputeGame and PermissionedDisputeGame with all the same
///         parameters as the existing implementations excluding the absolute prestate.
contract DeployDisputeGames is Script {
    using Strings for address;
    using LibDuration for Duration;
    using LibGameType for GameType;

    // TODO: Confirm expected version
    string public constant EXPECTED_VERSION = "1.4.1";

    SystemConfig internal _SYSTEM_CONFIG = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));
    Claim immutable absolutePrestate;

    FaultDisputeGame.GameConstructorParams fdgParams;
    FaultDisputeGame.GameConstructorParams pdgParams;
    address proposer;
    address challenger;

    constructor() {
        absolutePrestate = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));
    }

    function setUp() public {
        DisputeGameFactory dgfProxy = DisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGame currentFdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGame currentPdg =
            PermissionedDisputeGame(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        uint256 maxGameDepth = currentFdg.maxGameDepth();
        uint256 splitDepth = currentFdg.splitDepth();
        Duration clockExtension = currentFdg.clockExtension();
        Duration maxClockDuration = currentFdg.maxClockDuration();
        IBigStepper bigStepper = currentFdg.vm();
        IAnchorStateRegistry anchorStateRegistry = currentFdg.anchorStateRegistry();
        uint256 l2ChainId = currentFdg.l2ChainId();

        proposer = currentPdg.proposer();
        challenger = currentPdg.challenger();

        fdgParams = FaultDisputeGame.GameConstructorParams({
            gameType: GameTypes.CANNON,
            absolutePrestate: absolutePrestate,
            maxGameDepth: maxGameDepth,
            splitDepth: splitDepth,
            clockExtension: clockExtension,
            maxClockDuration: maxClockDuration,
            vm: bigStepper,
            weth: currentFdg.weth(),
            anchorStateRegistry: anchorStateRegistry,
            l2ChainId: l2ChainId
        });
        pdgParams = FaultDisputeGame.GameConstructorParams({
            gameType: GameTypes.PERMISSIONED_CANNON,
            absolutePrestate: absolutePrestate,
            maxGameDepth: maxGameDepth,
            splitDepth: splitDepth,
            clockExtension: clockExtension,
            maxClockDuration: maxClockDuration,
            vm: bigStepper,
            weth: currentPdg.weth(),
            anchorStateRegistry: anchorStateRegistry,
            l2ChainId: l2ChainId
        });
    }

    function _postCheck(address fdgImpl, address pdgImpl) private view {
        FaultDisputeGame fdg = FaultDisputeGame(fdgImpl);
        PermissionedDisputeGame pdg = PermissionedDisputeGame(pdgImpl);

        require(Strings.equal(fdg.version(), EXPECTED_VERSION), "Postcheck version 1");
        require(Strings.equal(pdg.version(), EXPECTED_VERSION), "Postcheck version 2");

        require(fdg.gameType().raw() == GameTypes.CANNON.raw(), "Postcheck 1");
        require(fdg.absolutePrestate().raw() == absolutePrestate.raw(), "Postcheck 2");
        require(fdg.maxGameDepth() == fdgParams.maxGameDepth, "Postcheck 3");
        require(fdg.splitDepth() == fdgParams.splitDepth, "Postcheck 4");
        require(fdg.clockExtension().raw() == fdgParams.clockExtension.raw(), "Postcheck 5");
        require(fdg.maxClockDuration().raw() == fdgParams.maxClockDuration.raw(), "Postcheck 6");
        require(fdg.vm() == fdgParams.vm, "Postcheck 7");
        require(fdg.weth() == fdgParams.weth, "Postcheck 8");
        require(fdg.anchorStateRegistry() == fdgParams.anchorStateRegistry, "Postcheck 9");
        require(fdg.l2ChainId() == fdgParams.l2ChainId, "Postcheck 10");

        require(pdg.gameType().raw() == GameTypes.PERMISSIONED_CANNON.raw(), "Postcheck 11");
        require(pdg.absolutePrestate().raw() == absolutePrestate.raw(), "Postcheck 12");
        require(pdg.maxGameDepth() == pdgParams.maxGameDepth, "Postcheck 13");
        require(pdg.splitDepth() == pdgParams.splitDepth, "Postcheck 14");
        require(pdg.clockExtension().raw() == pdgParams.clockExtension.raw(), "Postcheck 15");
        require(pdg.maxClockDuration().raw() == pdgParams.maxClockDuration.raw(), "Postcheck 16");
        require(pdg.vm() == pdgParams.vm, "Postcheck 17");
        require(pdg.weth() == pdgParams.weth, "Postcheck 18");
        require(pdg.anchorStateRegistry() == pdgParams.anchorStateRegistry, "Postcheck 19");
        require(pdg.l2ChainId() == pdgParams.l2ChainId, "Postcheck 20");
        require(pdg.proposer() == proposer, "Postcheck 21");
        require(pdg.challenger() == challenger, "Postcheck 22");
    }

    function run() public {
        (address fdg, address pdg) = _deployContracts();
        _postCheck(fdg, pdg);

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
        console.log("FaultDisputeGame params:");
        console.logBytes(abi.encode(fdgParams));

        console.log("PermissionedDisputeGame params:");
        console.logBytes(abi.encode(pdgParams, proposer, challenger));

        vm.startBroadcast();
        address fdg = address(new FaultDisputeGame(fdgParams));
        address pdg = address(new PermissionedDisputeGame(pdgParams, proposer, challenger));
        vm.stopBroadcast();

        return (fdg, pdg);
    }
}
