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

contract RollbackProposer is MultisigBuilder {
    address internal OLD_PROPOSER = vm.envAddress("OLD_PROPOSER");
    address internal DISPUTE_GAME_FACTORY_PROXY = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
    address internal PERMISSIONED_DISPUTE_GAME = vm.envAddress("PERMISSIONED_DISPUTE_GAME");
    address internal DISPUTE_GAME_FACTORY_PROXY_OWNER = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY_OWNER");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        DisputeGameFactory dGF = DisputeGameFactory(DISPUTE_GAME_FACTORY_PROXY);
        IDisputeGame gameImpl = dGF.gameImpls(GameTypes.PERMISSIONED_CANNON);
        require(PermissionedDisputeGame(address(gameImpl)).proposer() == OLD_PROPOSER, "Deploy: proposer is incorrect");
        console.log("Updated proposer to: ");
        console.log(OLD_PROPOSER);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        PermissionedDisputeGame newPdgImpl = PermissionedDisputeGame(PERMISSIONED_DISPUTE_GAME);
        require(newPdgImpl.proposer() == OLD_PROPOSER, "Deploy: proposer is incorrect");

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);
        calls[0] = IMulticall3.Call3({
            target: DISPUTE_GAME_FACTORY_PROXY,
            allowFailure: false,
            callData: abi.encodeCall(
                DisputeGameFactory.setImplementation,
                (GameTypes.PERMISSIONED_CANNON, IDisputeGame(PERMISSIONED_DISPUTE_GAME))
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return DISPUTE_GAME_FACTORY_PROXY_OWNER;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _incrementedNonce = _getNonce(safe) + 1;
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _incrementedNonce);
    }

    function _addGenericOverrides() internal view override returns (SimulationStateOverride memory) {
        SimulationStorageOverride[] memory _stateOverrides = new SimulationStorageOverride[](1);
        _stateOverrides[0] = SimulationStorageOverride({
            key: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e, // slot of PermissionedDisputeGame
            value: 0x000000000000000000000000c7f2cf4845c6db0e1a1e91ed41bcd0fcc1b0e141
        });
        return SimulationStateOverride({contractAddress: DISPUTE_GAME_FACTORY_PROXY, overrides: _stateOverrides});
    }
}
