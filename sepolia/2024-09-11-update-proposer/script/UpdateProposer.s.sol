// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";

contract UpdateProposer is MultisigBuilder {
    address internal NEW_PROPOSER = vm.envAddress("NEW_PROPOSER");
    address internal DISPUTE_GAME_FACTORY_PROXY = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal NEW_PERMISSIONED_DISPUTE_GAME = vm.envAddress("NEW_PERMISSIONED_DISPUTE_GAME");
    address internal DISPUTE_GAME_FACTORY_PROXY_OWNER = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY_OWNER");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        DisputeGameFactory dGF = DisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY);
        IDisputeGame gameImpl = dGF.gameImpls(GameTypes.PERMISSIONED_CANNON);
        require(PermissionedDisputeGame(address(gameImpl)).proposer() == NEW_PROPOSER, "Deploy: proposer is incorrect");
        console.log("Updated proposer to: ");
        console.log(NEW_PROPOSER);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        PermissionedDisputeGame newPdgImpl = PermissionedDisputeGame(NEW_PERMISSIONED_DISPUTE_GAME);
        require(newPdgImpl.proposer() == NEW_PROPOSER, "Deploy: proposer is incorrect");

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = IMulticall3.Call3({
            target: DISPUTE_GAME_FACTORY_PROXY,
            allowFailure: false,
            callData: abi.encodeCall(
                DisputeGameFactory.setImplementation, (GameTypes.PERMISSIONED_CANNON, IDisputeGame(address(newPdgImpl)))
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return DISPUTE_GAME_FACTORY_PROXY_OWNER;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}
