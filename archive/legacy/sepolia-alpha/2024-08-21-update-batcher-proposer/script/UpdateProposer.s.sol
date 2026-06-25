// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import "forge-std/Script.sol";

contract UpdateProposer is Script {
    address internal NEW_PROPOSER = vm.envAddress("NEW_PROPOSER");
    address internal DISPUTE_GAME_FACTORY_PROXY = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal PERMISSIONED_DISPUTE_GAME = vm.envAddress("PERMISSIONED_DISPUTE_GAME");
    address internal DISPUTE_GAME_FACTORY_PROXY_OWNER = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY_OWNER");

    function run() public {
        DisputeGameFactory dGF = DisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY);
        PermissionedDisputeGame pdg = PermissionedDisputeGame(PERMISSIONED_DISPUTE_GAME);

        console.log("Current proposer: ");
        console.log(pdg.proposer());

        vm.startBroadcast();
        PermissionedDisputeGame newPdgImpl = new PermissionedDisputeGame({
            _gameType: pdg.gameType(),
            _absolutePrestate: pdg.absolutePrestate(),
            _maxGameDepth: pdg.maxGameDepth(),
            _splitDepth: pdg.splitDepth(),
            _clockExtension: pdg.clockExtension(),
            _maxClockDuration: pdg.maxClockDuration(),
            _vm: pdg.vm(),
            _weth: pdg.weth(),
            _anchorStateRegistry: pdg.anchorStateRegistry(),
            _l2ChainId: pdg.l2ChainId(),
            _proposer: NEW_PROPOSER,
            _challenger: pdg.challenger()
        });

        // vm.prank(DISPUTE_GAME_FACTORY_PROXY_OWNER);
        dGF.setImplementation(GameTypes.PERMISSIONED_CANNON, IDisputeGame(address(newPdgImpl)));

        IDisputeGame gameImpl = dGF.gameImpls(GameTypes.PERMISSIONED_CANNON);
        require(address(gameImpl) == address(newPdgImpl), "Deploy: DisputeGameFactory implementation is incorrect");
        require(newPdgImpl.proposer() == NEW_PROPOSER, "Deploy: proposer is incorrect");
        console.log("Updated proposer to: ");
        console.log(NEW_PROPOSER);
        vm.stopBroadcast();
    }
}
