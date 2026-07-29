// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import "forge-std/Script.sol";

contract RollbackProposer is Script {
    address internal DISPUTE_GAME_FACTORY_PROXY = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal PERMISSIONED_DISPUTE_GAME = vm.envAddress("PERMISSIONED_DISPUTE_GAME");
    address internal DISPUTE_GAME_FACTORY_PROXY_OWNER = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY_OWNER");
    address internal OLD_PROPOSER = vm.envAddress("OLD_PROPOSER");

    function run() public {
        DisputeGameFactory dGF = DisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY);
        PermissionedDisputeGame pdg = PermissionedDisputeGame(PERMISSIONED_DISPUTE_GAME);

        // vm.prank(DISPUTE_GAME_FACTORY_PROXY_OWNER);
        dGF.setImplementation(GameTypes.PERMISSIONED_CANNON, IDisputeGame(address(pdg)));

        IDisputeGame gameImpl = dGF.gameImpls(GameTypes.PERMISSIONED_CANNON);
        require(address(gameImpl) == address(pdg), "Deploy: DisputeGameFactory implementation is incorrect");
        require(pdg.proposer() == OLD_PROPOSER, "Deploy: proposer is incorrect");
        console.log("Updated proposer to: ");
        console.log(pdg.proposer());
    }
}
