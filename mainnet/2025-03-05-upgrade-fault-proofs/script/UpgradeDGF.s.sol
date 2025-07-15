// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {console} from "forge-std/console.sol";

import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {DisputeGameFactory, IDisputeGame} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {GameTypes, GameType, Duration, Hash} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";

/// @notice This script updates the FaultDisputeGame and PermissionedDisputeGame implementations in the
///         DisputeGameFactory contract.
contract UpgradeDGF is NestedMultisigBuilder {
    using stdJson for string;

    address internal _OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    DisputeGameFactory dgfProxy;
    address fdgImpl;
    address pdgImpl;

    function setUp() public {
        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/addresses.json");
        string memory addresses = vm.readFile(path);

        dgfProxy = DisputeGameFactory(SystemConfig(vm.envAddress("SYSTEM_CONFIG")).disputeGameFactory());
        fdgImpl = addresses.readAddress(".faultDisputeGame");
        pdgImpl = addresses.readAddress(".permissionedDisputeGame");

        _precheckDisputeGameImplementation(GameTypes.CANNON, fdgImpl);
        _precheckDisputeGameImplementation(GameTypes.PERMISSIONED_CANNON, pdgImpl);
    }

    // Checks that the new game being set has the same configuration as the existing implementation with the exception
    // of the absolutePrestate. This is the most common scenario where the game implementation is upgraded to provide an
    // updated fault proof program that supports an upcoming hard fork.
    function _precheckDisputeGameImplementation(GameType targetGameType, address newImpl) internal view {
        console.log("pre-check new game implementations", targetGameType.raw());

        FaultDisputeGame currentImpl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(targetGameType))));
        // No checks are performed if there is no prior implementation.
        // When deploying the first implementation, it is recommended to implement custom checks.
        if (address(currentImpl) == address(0)) {
            return;
        }
        FaultDisputeGame faultDisputeGame = FaultDisputeGame(newImpl);
        require(address(currentImpl.vm()) == address(faultDisputeGame.vm()), "10");
        require(address(currentImpl.weth()) == address(faultDisputeGame.weth()), "20");
        require(address(currentImpl.anchorStateRegistry()) == address(faultDisputeGame.anchorStateRegistry()), "30");
        require(currentImpl.l2ChainId() == faultDisputeGame.l2ChainId(), "40");
        require(currentImpl.splitDepth() == faultDisputeGame.splitDepth(), "50");
        require(currentImpl.maxGameDepth() == faultDisputeGame.maxGameDepth(), "60");
        require(
            uint64(Duration.unwrap(currentImpl.maxClockDuration()))
                == uint64(Duration.unwrap(faultDisputeGame.maxClockDuration())),
            "70"
        );
        require(
            uint64(Duration.unwrap(currentImpl.clockExtension()))
                == uint64(Duration.unwrap(faultDisputeGame.clockExtension())),
            "80"
        );

        if (targetGameType.raw() == GameTypes.PERMISSIONED_CANNON.raw()) {
            PermissionedDisputeGame currentPDG = PermissionedDisputeGame(address(currentImpl));
            PermissionedDisputeGame permissionedDisputeGame = PermissionedDisputeGame(address(faultDisputeGame));
            require(address(currentPDG.proposer()) == address(permissionedDisputeGame.proposer()), "90");
            require(address(currentPDG.challenger()) == address(permissionedDisputeGame.challenger()), "100");
        }
    }

    // Confirm the stored implementations are updated and the anchor states still exist.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(address(dgfProxy.gameImpls(GameTypes.CANNON)) == fdgImpl, "post-110");
        require(address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)) == pdgImpl, "post-120");
        _postcheckHasAnchorState(GameTypes.CANNON);
        _postcheckHasAnchorState(GameTypes.PERMISSIONED_CANNON);
    }

    // Checks the anchor state for the source game type still exists after re-initialization. The actual anchor state
    // may have been updated since the task was defined so just assert it exists, not that it has a specific value.
    function _postcheckHasAnchorState(GameType gameType) internal view {
        console.log("check anchor state exists", gameType.raw());

        FaultDisputeGame impl = FaultDisputeGame(address(dgfProxy.gameImpls(GameType(gameType))));
        (Hash root, uint256 rootBlockNumber) = FaultDisputeGame(address(impl)).anchorStateRegistry().anchors(gameType);

        require(root.raw() != bytes32(0), "check-300");
        require(rootBlockNumber != 0, "check-310");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);

        calls[0] = IMulticall3.Call3({
            target: address(dgfProxy),
            allowFailure: false,
            callData: abi.encodeCall(DisputeGameFactory.setImplementation, (GameTypes.CANNON, IDisputeGame(fdgImpl)))
        });
        calls[1] = IMulticall3.Call3({
            target: address(dgfProxy),
            allowFailure: false,
            callData: abi.encodeCall(
                DisputeGameFactory.setImplementation, (GameTypes.PERMISSIONED_CANNON, IDisputeGame(pdgImpl))
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return _OWNER_SAFE;
    }
}
