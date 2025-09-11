// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";


contract SwapOwner is MultisigScript {
    using stdJson for string;

    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal constant SENTINEL_OWNERS = address(0x1);

    address[] public EXISTING_OWNERS;

    address[] public OWNERS_TO_ADD;
    address[] public OWNERS_TO_REMOVE;

    mapping(address => address) public ownerToPrevOwner;
    mapping(address => address) public ownerToNextOwner;
    mapping(address => bool) public expectedOwner;
    uint256 public immutable THRESHOLD;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");

        IGnosisSafe ownerSafe = IGnosisSafe(OWNER_SAFE);
        THRESHOLD = ownerSafe.getThreshold();
        EXISTING_OWNERS = ownerSafe.getOwners();

        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/OwnerDiff.json");
        string memory jsonData = vm.readFile(path);

        OWNERS_TO_ADD = abi.decode(jsonData.parseRaw(".OwnersToAdd"), (address[]));
        OWNERS_TO_REMOVE = abi.decode(jsonData.parseRaw(".OwnersToRemove"), (address[]));
    }

    function setUp() public {
        require(OWNERS_TO_ADD.length > 0);
        require(OWNERS_TO_REMOVE.length > 0);
        address prevOwner = SENTINEL_OWNERS;
        IGnosisSafe ownerSafe = IGnosisSafe(payable(OWNER_SAFE));

        for (uint256 i = OWNERS_TO_ADD.length; i > 0; i--) {
            uint256 index = i - 1;
            // Make sure owners to add are not already owners
            require(!ownerSafe.isOwner(OWNERS_TO_ADD[index]), "New owner already owner");
            // Prevent duplicates
            require(!expectedOwner[OWNERS_TO_ADD[index]], "Duplicate owner detected");

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

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls =
            new IMulticall3.Call3Value[](OWNERS_TO_ADD.length + OWNERS_TO_REMOVE.length);

        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            calls[i] = IMulticall3.Call3Value({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(IGnosisSafe.addOwnerWithThreshold, (OWNERS_TO_ADD[i], THRESHOLD)),
                value: 0
            });
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            calls[OWNERS_TO_ADD.length + i] = IMulticall3.Call3Value({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(
                    IGnosisSafe.removeOwner, (ownerToPrevOwner[OWNERS_TO_REMOVE[i]], OWNERS_TO_REMOVE[i], THRESHOLD)
                ),
                value: 0
            });
        }

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IGnosisSafe ownerSafe = IGnosisSafe(OWNER_SAFE);
        address[] memory postCheckOwners = ownerSafe.getOwners();
        uint256 postCheckThreshold = ownerSafe.getThreshold();

        uint256 expectedLength = EXISTING_OWNERS.length + OWNERS_TO_ADD.length - OWNERS_TO_REMOVE.length;

        require(postCheckThreshold == THRESHOLD, "Postcheck 00");
        require(postCheckOwners.length == expectedLength, "Postcheck 01");

        for (uint256 i; i < postCheckOwners.length; i++) {
            require(expectedOwner[postCheckOwners[i]], "Postcheck 02");
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
