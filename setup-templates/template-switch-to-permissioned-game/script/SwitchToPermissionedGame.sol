// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IAnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {GameTypes, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

/// @notice This script updates the respectedGameType and retires existing games in the AnchorStateRegistry.
contract SwitchToPermissionedGame is MultisigScript {
    // TODO: Confirm expected version
    string public constant EXPECTED_VERSION = "1.4.1";

    address public immutable OWNER_SAFE;
    uint64 public currentRetirementTimestamp;

    SystemConfig internal immutable _SYSTEM_CONFIG = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));

    IAnchorStateRegistry anchorStateRegistry;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    }

    function setUp() public {
        DisputeGameFactory dgfProxy = DisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGame currentFdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        anchorStateRegistry = currentFdg.anchorStateRegistry();
        currentRetirementTimestamp = anchorStateRegistry.retirementTimestamp();
    }

    // Confirm the currentRetirementTimestamp is updated to the block time and the
    // respectedGameType is updated to PERMISSIONED_CANNON.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(anchorStateRegistry.retirementTimestamp() == block.timestamp, "post-110");
        require(
            GameType.unwrap(anchorStateRegistry.respectedGameType()) == GameType.unwrap(GameTypes.PERMISSIONED_CANNON),
            "post-111"
        );
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        calls[0] = IMulticall3.Call3Value({
            target: address(anchorStateRegistry),
            allowFailure: false,
            callData: abi.encodeCall(IAnchorStateRegistry.setRespectedGameType, (GameTypes.PERMISSIONED_CANNON)),
            value: 0
        });

        calls[1] = IMulticall3.Call3Value({
            target: address(anchorStateRegistry),
            allowFailure: false,
            callData: abi.encodeCall(IAnchorStateRegistry.updateRetirementTimestamp, ()),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
