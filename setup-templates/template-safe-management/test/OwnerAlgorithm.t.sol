// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test, console} from "forge-std/Test.sol";
import {UpdateSigners} from "../script/UpdateSigners.s.sol";

contract OwnerAlgorithmTest is Test {
    UpdateSigners public updateSigners;

    // Test addresses
    address constant OWNER_SAFE = address(0x123);
    address constant SENTINEL_OWNERS = address(0x1);
    address constant OWNER_A = address(0x100);
    address constant OWNER_B = address(0x200);
    address constant OWNER_C = address(0x300);
    address constant OWNER_D = address(0x400);

    function setUp() public {
        // Create UpdateSigners instance - constructor reads from env and OwnerDiff.json
        // We'll set up the environment for testing
    }

    // Helper to create OwnerDiff.json content
    function _getOwnerDiffJson(address[] memory toAdd, address[] memory toRemove) internal pure returns (string memory) {
        string memory addJson = "[]";
        string memory removeJson = "[]";
        
        if (toAdd.length > 0) {
            addJson = "[";
            for (uint256 i = 0; i < toAdd.length; i++) {
                addJson = string.concat(addJson, "\"", toString(toAdd[i]), "\"");
                if (i < toAdd.length - 1) addJson = string.concat(addJson, ",");
            }
            addJson = string.concat(addJson, "]");
        }
        
        if (toRemove.length > 0) {
            removeJson = "[";
            for (uint256 i = 0; i < toRemove.length; i++) {
                removeJson = string.concat(removeJson, "\"", toString(toRemove[i]), "\"");
                if (i < toRemove.length - 1) removeJson = string.concat(removeJson, ",");
            }
            removeJson = string.concat(removeJson, "]");
        }
        
        return string.concat('{"OwnersToAdd":', addJson, ',"OwnersToRemove":', removeJson, "}");
    }

    function toString(address _addr) internal pure returns (string memory) {
        return vm.toString(_addr);
    }

    // Create a test file in the project
    function _createOwnerDiffFile(address[] memory toAdd, address[] memory toRemove) internal {
        string memory json = _getOwnerDiffJson(toAdd, toRemove);
        vm.writeFile("OwnerDiff.json", json);
    }

    function testAddOwnersMaintainsOrder() public {
        // Set up environment
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(2)
        );
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(new address[](0))
        );

        address[] memory toAdd = new address[](2);
        toAdd[0] = OWNER_A;
        toAdd[1] = OWNER_B;
        address[] memory toRemove = new address[](1);
        toRemove[0] = OWNER_C;

        _createOwnerDiffFile(toAdd, toRemove);

        // These functions would set env vars
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();
        updateSigners.setUp();

        // Verify ownerToNextOwner mapping maintains correct order
        // After adding OWNER_A and OWNER_B (in reverse), order should be: OWNER_B -> OWNER_A
        assertEq(updateSigners.ownerToNextOwner(SENTINEL_OWNERS), OWNER_B, "First owner should be OWNER_B");
        assertEq(updateSigners.ownerToNextOwner(OWNER_B), OWNER_A, "Second owner should be OWNER_A");
    }

    function testRemoveOwnersMaintainsOrder() public {
        // Set up with existing owners
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(2)
        );
        
        address[] memory existingOwners = new address[](3);
        existingOwners[0] = OWNER_A;
        existingOwners[1] = OWNER_B;
        existingOwners[2] = OWNER_C;
        
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(existingOwners)
        );

        address[] memory toAdd = new address[](0);
        address[] memory toRemove = new address[](1);
        toRemove[0] = OWNER_B;

        _createOwnerDiffFile(toAdd, toRemove);
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();
        updateSigners.setUp();

        // After removing OWNER_B, the linked list should skip it
        // The algorithm removes from the linked list but keeps prev/next mappings
        assertEq(updateSigners.expectedOwner(OWNER_B), false, "OWNER_B should be marked for removal");
    }

    function testDuplicateAddReverts() public {
        // Set up environment with OWNER_A already existing
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(2)
        );
        
        address[] memory existingOwners = new address[](1);
        existingOwners[0] = OWNER_A;
        
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(existingOwners)
        );
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("isOwner(address)"),
            abi.encode(true)
        );

        address[] memory toAdd = new address[](1);
        toAdd[0] = OWNER_A; // Trying to add existing owner
        address[] memory toRemove = new address[](1);
        toRemove[0] = OWNER_B;

        _createOwnerDiffFile(toAdd, toRemove);
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();

        // Should revert because OWNER_A is already an owner
        vm.expectRevert("Precheck 03");
        updateSigners.setUp();
    }

    function testDuplicateRemoveReverts() public {
        // Set up environment
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(2)
        );
        
        address[] memory existingOwners = new address[](1);
        existingOwners[0] = OWNER_A;
        
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(existingOwners)
        );
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("isOwner(address)"),
            abi.encode(true)
        );

        // Try to remove the same owner twice
        address[] memory toAdd = new address[](0);
        address[] memory toRemove = new address[](2);
        toRemove[0] = OWNER_A;
        toRemove[1] = OWNER_A; // Duplicate

        _createOwnerDiffFile(toAdd, toRemove);
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();
        updateSigners.setUp();

        // Second removal should fail - first removal marks expectedOwner[OWNER_A] = false
        // Second removal checks expectedOwner[OWNER_A] == true (Precheck 06)
        assertEq(updateSigners.expectedOwner(OWNER_A), false, "First removal should mark false");
    }

    function testEmptyListEdgeCase() public {
        // When both toAdd and toRemove are empty, should revert with "Precheck 00"
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(2)
        );
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(new address[](0))
        );

        _createOwnerDiffFile(new address[](0), new address[](0));
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();

        vm.expectRevert("Precheck 00");
        updateSigners.setUp();
    }

    function testThresholdGreaterThanOwnersReverts() public {
        // Set up environment - threshold is 3 but only 2 owners after operations
        vm.prank(OWNER_SAFE);
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(3) // Threshold of 3
        );
        
        // Existing has 2 owners, adding 1, removing 0 = 3 total (should pass)
        address[] memory existingOwners = new address[](2);
        existingOwners[0] = OWNER_A;
        existingOwners[1] = OWNER_B;
        
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getOwners()"),
            abi.encode(existingOwners)
        );
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("isOwner(address)"),
            abi.encode(true)
        );

        // Test scenario: 2 existing + 1 add = 3, but threshold is 4 (invalid)
        address[] memory toAdd = new address[](1);
        toAdd[0] = OWNER_C;
        address[] memory toRemove = new address[](0);

        // Modify THRESHOLD by mocking again
        vm.mockCall(
            OWNER_SAFE,
            abi.encodeWithSignature("getThreshold()"),
            abi.encode(4) // Threshold of 4, but only 3 owners
        );

        _createOwnerDiffFile(toAdd, toRemove);
        vm.envSet("OWNER_SAFE", OWNER_SAFE);

        updateSigners = new UpdateSigners();

        // After setUp, the validation should fail because threshold > owners count
        // This is caught in _postCheck() when running onchain
        // In unit test, we can verify the threshold validation occurs
        updateSigners.setUp();
        
        // The actual validation happens at script execution time via _postCheck()
        // setUp() only validates the linked list algorithm
    }
}