// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {
    IDelayedWETH,
    IAnchorStateRegistry,
    IBigStepper
} from "@eth-optimism-bedrock/src/dispute/v2/FaultDisputeGameV2.sol";
import {
    FaultDisputeGameV2,
    PermissionedDisputeGameV2
} from "@eth-optimism-bedrock/src/dispute/v2/PermissionedDisputeGameV2.sol";
import {GameTypes, GameType, Duration, Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {LibGameType, LibDuration} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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

    FaultDisputeGameV2.GameConstructorParams dgParams;
    address proposer;
    address challenger;

    constructor() {
        absolutePrestate = Claim.wrap(vm.envBytes32("ABSOLUTE_PRESTATE"));
    }

    function setUp() public {
        DisputeGameFactory dgfProxy = DisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGameV2 currentFdg = FaultDisputeGameV2(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        PermissionedDisputeGameV2 currentPdg =
            PermissionedDisputeGameV2(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)));

        uint256 maxGameDepth = currentFdg.maxGameDepth();
        uint256 splitDepth = currentFdg.splitDepth();
        Duration clockExtension = currentFdg.clockExtension();
        Duration maxClockDuration = currentFdg.maxClockDuration();

        proposer = currentPdg.proposer();
        challenger = currentPdg.challenger();

        dgParams = FaultDisputeGameV2.GameConstructorParams({
            maxGameDepth: maxGameDepth,
            splitDepth: splitDepth,
            clockExtension: clockExtension,
            maxClockDuration: maxClockDuration
        });
    }

    function _postCheck(address fdgImpl, address pdgImpl) private view {
        FaultDisputeGameV2 fdg = FaultDisputeGameV2(fdgImpl);
        PermissionedDisputeGameV2 pdg = PermissionedDisputeGameV2(pdgImpl);

        require(Strings.equal(fdg.version(), EXPECTED_VERSION), "Postcheck version 1");
        require(Strings.equal(pdg.version(), EXPECTED_VERSION), "Postcheck version 2");

        require(fdg.gameType().raw() == GameTypes.CANNON.raw(), "Postcheck 1");
        require(fdg.absolutePrestate().raw() == absolutePrestate.raw(), "Postcheck 2");
        require(fdg.maxGameDepth() == dgParams.maxGameDepth, "Postcheck 3");
        require(fdg.splitDepth() == dgParams.splitDepth, "Postcheck 4");
        require(fdg.clockExtension().raw() == dgParams.clockExtension.raw(), "Postcheck 5");
        require(fdg.maxClockDuration().raw() == dgParams.maxClockDuration.raw(), "Postcheck 6");
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
        console.logBytes(abi.encode(dgParams));

        console.log("PermissionedDisputeGame params:");
        console.logBytes(abi.encode(dgParams));

        vm.startBroadcast();
        address fdg = address(new FaultDisputeGameV2(dgParams));
        address pdg = address(new PermissionedDisputeGameV2(dgParams));
        vm.stopBroadcast();

        return (fdg, pdg);
    }
}
