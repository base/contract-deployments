// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {GnosisSafe} from "safe-smart-account/GnosisSafe.sol";
import {OwnerManager} from "safe-smart-account/base/OwnerManager.sol";

contract UpdateSigners is MultisigScript {
    using stdJson for string;

    address public constant SENTINEL_OWNERS = address(0x1);

    address public immutable OWNER_SAFE;
    uint256 public immutable EXISTING_OWNERS_LENGTH;
    uint256 public immutable THRESHOLD;
    address[] public EXISTING_OWNERS;

    address[] public OWNERS_TO_ADD;
    address[] public OWNERS_TO_REMOVE;

    mapping(address => address) public ownerToPrevOwner;
    mapping(address => address) public ownerToNextOwner;
    mapping(address => bool) public expectedOwner;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        EXISTING_OWNERS_LENGTH = vm.envUint("EXISTING_OWNERS_LENGTH");

        GnosisSafe ownerSafe = GnosisSafe(payable(OWNER_SAFE));
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
        require(EXISTING_OWNERS.length == EXISTING_OWNERS_LENGTH, "Precheck 02");

        GnosisSafe ownerSafe = GnosisSafe(payable(OWNER_SAFE));
        address prevOwner = SENTINEL_OWNERS;

        // Build the linked list from the current on-chain owners first.
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
        }

        // Validate owners to add are not already owners and mark as expected post-state owners.
        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            // Make sure owners to add are not already owners
            require(!ownerSafe.isOwner(OWNERS_TO_ADD[i]), "Precheck 03");
            // Prevent duplicates across the adds list
            require(!expectedOwner[OWNERS_TO_ADD[i]], "Precheck 04");
            expectedOwner[OWNERS_TO_ADD[i]] = true;
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        GnosisSafe ownerSafe = GnosisSafe(payable(OWNER_SAFE));
        address[] memory postCheckOwners = ownerSafe.getOwners();
        uint256 postCheckThreshold = ownerSafe.getThreshold();

        uint256 expectedLength = EXISTING_OWNERS.length + OWNERS_TO_ADD.length - OWNERS_TO_REMOVE.length;

        require(postCheckThreshold == THRESHOLD, "Postcheck 00");
        require(postCheckOwners.length == expectedLength, "Postcheck 01");

        for (uint256 i; i < postCheckOwners.length; i++) {
            require(expectedOwner[postCheckOwners[i]], "Postcheck 02");
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls =
            new IMulticall3.Call3Value[](OWNERS_TO_ADD.length + OWNERS_TO_REMOVE.length);

        // Create a working copy of the current owners. We'll mutate this in-memory as we plan removals
        address[] memory workingOwners = new address[](EXISTING_OWNERS.length);
        for (uint256 i; i < EXISTING_OWNERS.length; i++) {
            workingOwners[i] = EXISTING_OWNERS[i];
        }

        // 1) Build removal calls sequentially, deriving prev from the current working list each time
        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            address owner = OWNERS_TO_REMOVE[i];
            (bool found, uint256 idx) = _findIndex(workingOwners, owner);
            require(found, "owner to remove not in working set");

            address prev = SENTINEL_OWNERS;
            if (idx > 0) {
                uint256 j = idx;
                while (j > 0) {
                    j--;
                    if (workingOwners[j] != address(0)) {
                        prev = workingOwners[j];
                        break;
                    }
                }
            }

            calls[i] = IMulticall3.Call3Value({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(OwnerManager.removeOwner, (prev, owner, THRESHOLD)),
                value: 0
            });

            // Mark the owner as removed for subsequent predecessor computations
            workingOwners[idx] = address(0);
        }

        // 2) Then add the new owners, keeping the threshold unchanged.
        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            calls[OWNERS_TO_REMOVE.length + i] = IMulticall3.Call3Value({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(OwnerManager.addOwnerWithThreshold, (OWNERS_TO_ADD[i], THRESHOLD)),
                value: 0
            });
        }

        return calls;
    }

    function _findIndex(address[] memory arr, address needle) internal pure returns (bool, uint256) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] == needle) return (true, i);
        }
        return (false, 0);
    }

    function _prevInList(address[] memory list, address owner) internal pure returns (address) {
        for (uint256 i; i < list.length; i++) {
            if (list[i] == owner) {
                return i == 0 ? SENTINEL_OWNERS : list[i - 1];
            }
        }
        return SENTINEL_OWNERS;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
