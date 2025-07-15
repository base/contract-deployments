// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {console} from "forge-std/console.sol";

import {DoubleNestedMultisigBuilder} from "@base-contracts/script/universal/DoubleNestedMultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IDisputeGameFactory {
    function gameImpls(uint32) external view returns (address);
    function setImplementation(uint32, address) external;
}

interface IPermissionedDisputeGame {
    function challenger() external view returns (address);
    function proposer() external view returns (address);
}

interface ISystemConfig {
    function disputeGameFactory() external view returns (address);
}

interface IFaultDisputeGame {
    function version() external view returns (string memory);
    function vm() external view returns (address);
    function weth() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function l2ChainId() external view returns (uint64);
    function splitDepth() external view returns (uint64);
    function maxGameDepth() external view returns (uint64);
    function maxClockDuration() external view returns (uint64);
    function clockExtension() external view returns (uint64);
}

interface IAnchorStateRegistry {
    function anchors(uint32) external view returns (bytes32, uint256);
}

/// @notice This script updates the FaultDisputeGame and PermissionedDisputeGame implementations in the
///         DisputeGameFactory contract.
contract UpgradeDGF is DoubleNestedMultisigBuilder {
    using stdJson for string;

    // TODO: Confirm expected version
    string public constant EXPECTED_VERSION = "1.4.1";
    uint32 public constant CANNON = 0;
    uint32 public constant PERMISSIONED_CANNON = 1;

    address public immutable OWNER_SAFE;

    IDisputeGameFactory public dgfProxy;
    address public fdgImpl;
    address public pdgImpl;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    }

    function setUp() public {
        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/addresses.json");
        string memory addresses = vm.readFile(path);

        dgfProxy = IDisputeGameFactory(ISystemConfig(vm.envAddress("SYSTEM_CONFIG")).disputeGameFactory());
        fdgImpl = addresses.readAddress(".faultDisputeGame");
        pdgImpl = addresses.readAddress(".permissionedDisputeGame");

        _precheckDisputeGameImplementation(CANNON, fdgImpl);
        _precheckDisputeGameImplementation(PERMISSIONED_CANNON, pdgImpl);
    }

    // Checks that the new game being set has the same configuration as the existing implementation with the exception
    // of the absolutePrestate. This is the most common scenario where the game implementation is upgraded to provide an
    // updated fault proof program that supports an upcoming hard fork.
    function _precheckDisputeGameImplementation(uint32 targetGameType, address newImpl) internal view {
        console.log("pre-check new game implementations", targetGameType);

        IFaultDisputeGame currentImpl = IFaultDisputeGame(address(dgfProxy.gameImpls(targetGameType)));
        // No checks are performed if there is no prior implementation.
        // When deploying the first implementation, it is recommended to implement custom checks.
        if (address(currentImpl) == address(0)) {
            return;
        }
        IFaultDisputeGame faultDisputeGame = IFaultDisputeGame(newImpl);
        require(Strings.equal(currentImpl.version(), EXPECTED_VERSION), "00");
        require(currentImpl.vm() == faultDisputeGame.vm(), "10");
        require(currentImpl.weth() == faultDisputeGame.weth(), "20");
        require(currentImpl.anchorStateRegistry() == faultDisputeGame.anchorStateRegistry(), "30");
        require(currentImpl.l2ChainId() == faultDisputeGame.l2ChainId(), "40");
        require(currentImpl.splitDepth() == faultDisputeGame.splitDepth(), "50");
        require(currentImpl.maxGameDepth() == faultDisputeGame.maxGameDepth(), "60");
        require(currentImpl.maxClockDuration() == faultDisputeGame.maxClockDuration(), "70");
        require(currentImpl.clockExtension() == faultDisputeGame.clockExtension(), "80");

        if (targetGameType == PERMISSIONED_CANNON) {
            IPermissionedDisputeGame currentPDG = IPermissionedDisputeGame(address(currentImpl));
            IPermissionedDisputeGame permissionedDisputeGame = IPermissionedDisputeGame(address(faultDisputeGame));
            require(currentPDG.proposer() == permissionedDisputeGame.proposer(), "90");
            require(currentPDG.challenger() == permissionedDisputeGame.challenger(), "100");
        }
    }

    // Confirm the stored implementations are updated and the anchor states still exist.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(dgfProxy.gameImpls(CANNON) == fdgImpl, "post-110");
        require(dgfProxy.gameImpls(PERMISSIONED_CANNON) == pdgImpl, "post-120");
        _postcheckHasAnchorState(CANNON);
        _postcheckHasAnchorState(PERMISSIONED_CANNON);
    }

    // Checks the anchor state for the source game type still exists after re-initialization. The actual anchor state
    // may have been updated since the task was defined so just assert it exists, not that it has a specific value.
    function _postcheckHasAnchorState(uint32 gameType) internal view {
        console.log("check anchor state exists", gameType);

        IFaultDisputeGame impl = IFaultDisputeGame(dgfProxy.gameImpls(gameType));
        (bytes32 root, uint256 rootBlockNumber) = IAnchorStateRegistry(impl.anchorStateRegistry()).anchors(gameType);

        require(root != bytes32(0), "check-300");
        require(rootBlockNumber != 0, "check-310");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);

        calls[0] = IMulticall3.Call3({
            target: address(dgfProxy),
            allowFailure: false,
            callData: abi.encodeCall(IDisputeGameFactory.setImplementation, (CANNON, fdgImpl))
        });
        calls[1] = IMulticall3.Call3({
            target: address(dgfProxy),
            allowFailure: false,
            callData: abi.encodeCall(IDisputeGameFactory.setImplementation, (PERMISSIONED_CANNON, pdgImpl))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
