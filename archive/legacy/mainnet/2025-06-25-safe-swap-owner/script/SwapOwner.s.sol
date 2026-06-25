// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@base-contracts/script/universal/MultisigBuilder.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract SwapOwner is MultisigBuilder {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal OLD_SIGNER = vm.envAddress("OLD_SIGNER");
    address internal NEW_SIGNER = vm.envAddress("NEW_SIGNER");
    address internal constant SENTINEL_OWNERS = address(0x1);

    address[] internal safeOwners; // The list of all owners of the safe
    address internal prevOwnerLinked; // The previous owner in Safe's linked list of owners

    function setUp() public {
        safeOwners = IGnosisSafe(OWNER_SAFE).getOwners();
        _precheck();

        // We need to locate the previous owner in the linked list of owners to properly swap out the target signer
        for (uint256 i = 0; i < safeOwners.length; i++) {
            if (safeOwners[i] == OLD_SIGNER) {
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
        require(IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER), "Signer to swap is not an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER), "New signer is already an owner");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        // While more roundabout then simply calling execTransaction with a swapOwner call, this still works and lets us use our existing tooling
        calls[0] = IMulticall3.Call3Value({
            target: OWNER_SAFE,
            allowFailure: false,
            callData: abi.encodeCall(IGnosisSafe.swapOwner, (prevOwnerLinked, OLD_SIGNER, NEW_SIGNER)),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(IGnosisSafe(OWNER_SAFE).isOwner(NEW_SIGNER), "New signer was not added as an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OLD_SIGNER), "Old signer was not removed as an owner");
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
