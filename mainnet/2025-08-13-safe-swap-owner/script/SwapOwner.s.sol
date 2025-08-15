// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Vm} from "forge-std/Vm.sol";

contract SwapOwner is MultisigBuilder {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal OLD_SIGNER_1 = vm.envAddress("OLD_SIGNER_1");
    address internal OLD_SIGNER_2 = vm.envAddress("OLD_SIGNER_2");
    address internal OLD_SIGNER_3 = vm.envAddress("OLD_SIGNER_3");
    address internal OLD_SIGNER_4 = vm.envAddress("OLD_SIGNER_4");
    address internal OLD_SIGNER_5 = vm.envAddress("OLD_SIGNER_5");
    address internal OLD_SIGNER_6 = vm.envAddress("OLD_SIGNER_6");
    address internal NEW_SIGNER_1 = vm.envAddress("NEW_SIGNER_1");
    address internal NEW_SIGNER_2 = vm.envAddress("NEW_SIGNER_2");
    address internal NEW_SIGNER_3 = vm.envAddress("NEW_SIGNER_3");
    address internal NEW_SIGNER_4 = vm.envAddress("NEW_SIGNER_4");
    address internal NEW_SIGNER_5 = vm.envAddress("NEW_SIGNER_5");
    address internal NEW_SIGNER_6 = vm.envAddress("NEW_SIGNER_6");
    address internal NEW_SIGNER_7 = vm.envAddress("NEW_SIGNER_7");
    address internal constant SENTINEL_OWNERS = address(0x1);

    address[] internal safeOwners; // The list of all owners of the safe
    uint256 currentThreshold; // The current signature threshold

    function setUp() public {
        safeOwners = IGnosisSafe(OWNER_SAFE).getOwners();
        currentThreshold = IGnosisSafe(OWNER_SAFE).getThreshold();
        _precheck();
    }

    function _fetchPrevOwnerLinked(address owner) internal view returns (address prevOwnerLinked) {
        // We need to locate the previous owner in the linked list of owners to properly swap out the target signer
        for (uint256 i = 0; i < safeOwners.length; i++) {
            if (safeOwners[i] == owner) {
                // There is a sentinel node as the head of the linked list, so we need to handle the first owner separately
                if (i == 0) {
                    prevOwnerLinked = SENTINEL_OWNERS;
                } else {
                    prevOwnerLinked = safeOwners[i - 1];
                }
                break;
            }
        }
    }

    function _precheck() internal view {
        // Sanity checks on the current owner state of the safe
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_1), "Signer to swap is not an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_2), "Signer to swap is not an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_3), "Signer to swap is not an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_4), "Signer to swap is not an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_5), "Signer to swap is not an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_6), "Signer to swap is not an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_1), "New signer is already an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_2), "New signer is already an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_3), "New signer is already an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_4), "New signer is already an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_5), "New signer is already an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_6), "New signer is already an owner");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](7);

        calls[0] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_1), OLD_SIGNER_1, NEW_SIGNER_1))
        });
        calls[1] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_2), OLD_SIGNER_2, NEW_SIGNER_2))
        });
        calls[2] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_3), OLD_SIGNER_3, NEW_SIGNER_3))
        });
        calls[3] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_4), OLD_SIGNER_4, NEW_SIGNER_4))
        });
        calls[4] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_5), OLD_SIGNER_5, NEW_SIGNER_5))
        });
        calls[5] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_6), OLD_SIGNER_6, NEW_SIGNER_6))
        });
        calls[5] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (_fetchPrevOwnerLinked(OLD_SIGNER_6), OLD_SIGNER_6, NEW_SIGNER_6))
        });
        calls[6] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe.addOwnerWithThreshold, (NEW_SIGNER_7, currentThreshold))
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_1), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_2), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_3), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_4), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_5), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_6), "New signer was not added as an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER_7), "New signer was not added as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_1), "Old signer was not removed as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_2), "Old signer was not removed as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_3), "Old signer was not removed as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_4), "Old signer was not removed as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_5), "Old signer was not removed as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER_6), "Old signer was not removed as an owner");
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
