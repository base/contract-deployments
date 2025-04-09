// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {OwnerManager} from "safe-smart-account/contracts/base/OwnerManager.sol";

contract UpdateSigners is MultisigBuilder {
    using stdJson for string;

    address public constant SENTINEL_OWNERS = address(0x1);

    address public immutable OWNER_SAFE;
    uint256 public immutable THRESHOLD;
    address[] public EXISTING_OWNERS;

    address[] public OWNERS_TO_ADD;
    address[] public OWNERS_TO_REMOVE;

    mapping(address => address) public ownerToPrevOwner;
    mapping(address => address) public ownerToNextOwner;
    mapping(address => bool) public expectedOwner;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");

        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        THRESHOLD = ownerSafe.getThreshold();
        EXISTING_OWNERS = ownerSafe.getOwners();

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/OwnerDiff.json");
        string memory jsonData = vm.readFile(path);

        OWNERS_TO_ADD = abi.decode(jsonData.parseRaw(".OwnersToAdd"), (address[]));
        OWNERS_TO_REMOVE = abi.decode(jsonData.parseRaw(".OwnersToRemove"), (address[]));
    }

    function setUp() external {
        require(OWNERS_TO_ADD.length > 0, "Precheck 00");
        require(OWNERS_TO_REMOVE.length > 0, "Precheck 01");
        require(EXISTING_OWNERS.length == 14, "Precheck 02");

        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        address prevOwner = SENTINEL_OWNERS;

        for (uint256 i = OWNERS_TO_ADD.length; i > 0; i--) {
            uint256 index = i - 1;
            // Make sure owners to add are not already owners
            require(!ownerSafe.isOwner(OWNERS_TO_ADD[index]), "Precheck 03");
            // Prevent duplicates
            require(!expectedOwner[OWNERS_TO_ADD[index]], "Precheck 04");

            ownerToPrevOwner[OWNERS_TO_ADD[index]] = prevOwner;
            ownerToNextOwner[prevOwner] = OWNERS_TO_ADD[index];
            prevOwner = OWNERS_TO_ADD[index];
            expectedOwner[OWNERS_TO_ADD[index]] = true;
        }

        for (uint256 i; i < EXISTING_OWNERS.length; i++) {
            ownerToPrevOwner[EXISTING_OWNERS[i]] = prevOwner;
            ownerToNextOwner[prevOwner] = EXISTING_OWNERS[i];
            prevOwner = EXISTING_OWNERS[i];
            expectedOwner[EXISTING_OWNERS[i]] = true;
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            // Make sure owners to remove are owners
            require(ownerSafe.isOwner(OWNERS_TO_REMOVE[i]), "Precheck 05");
            // Prevent duplicates
            require(expectedOwner[OWNERS_TO_REMOVE[i]], "Precheck 06");
            expectedOwner[OWNERS_TO_REMOVE[i]] = false;

            // Remove from linked list to keep ownerToPrevOwner up to date
            // Note: This works as long as the order of OWNERS_TO_REMOVE does not change during `_buildCalls()`
            address nextOwner = ownerToNextOwner[OWNERS_TO_REMOVE[i]];
            address prevPtr = ownerToPrevOwner[OWNERS_TO_REMOVE[i]];
            ownerToPrevOwner[nextOwner] = prevPtr;
            ownerToNextOwner[prevPtr] = nextOwner;
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        Safe ownerSafe = Safe(payable(OWNER_SAFE));
        address[] memory postCheckOwners = ownerSafe.getOwners();
        uint256 postCheckThreshold = ownerSafe.getThreshold();

        uint256 expectedLength = EXISTING_OWNERS.length + OWNERS_TO_ADD.length - OWNERS_TO_REMOVE.length;

        require(postCheckThreshold == THRESHOLD, "Postcheck 00");
        require(postCheckOwners.length == expectedLength, "Postcheck 01");

        for (uint256 i; i < postCheckOwners.length; i++) {
            require(expectedOwner[postCheckOwners[i]], "Postcheck 02");
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](OWNERS_TO_ADD.length + OWNERS_TO_REMOVE.length);

        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            calls[i] = IMulticall3.Call3({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(OwnerManager.addOwnerWithThreshold, (OWNERS_TO_ADD[i], THRESHOLD))
            });
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            calls[OWNERS_TO_ADD.length + i] = IMulticall3.Call3({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(
                    OwnerManager.removeOwner, (ownerToPrevOwner[OWNERS_TO_REMOVE[i]], OWNERS_TO_REMOVE[i], THRESHOLD)
                )
            });
        }

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
