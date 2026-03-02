// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @title AddSecurityCouncilSigner
/// @notice Adds a new signer to the Security Council Safe and increases the threshold to 3.
/// @dev Uses addOwnerWithThreshold to add the new signer and set the threshold in a single call.
contract AddSecurityCouncilSigner is MultisigScript {
    /// @notice The new threshold after adding the signer.
    uint256 public constant NEW_THRESHOLD = 8;

    /// @notice The Security Council Safe whose signers are being updated.
    address public immutable SECURITY_COUNCIL = vm.envAddress("CB_SC_SAFE_ADDR");

    /// @notice The new signer address to be added.
    address public immutable NEW_SIGNER = vm.envAddress("NEW_SC_SIGNER_ADDR");

    /// @notice The current threshold before the update.
    uint256 public currentThreshold;

    /// @notice The current number of owners before the update.
    uint256 public currentOwnerCount;

    function setUp() external {
        // Prechecks: Verify initial state
        require(!IGnosisSafe(SECURITY_COUNCIL).isOwner(NEW_SIGNER), "Precheck: NEW_SIGNER must not already be an owner");

        currentThreshold = IGnosisSafe(SECURITY_COUNCIL).getThreshold();
        currentOwnerCount = IGnosisSafe(SECURITY_COUNCIL).getOwners().length;

        require(currentThreshold < NEW_THRESHOLD, "Precheck: Current threshold must be less than NEW_THRESHOLD");
        require(currentOwnerCount + 1 >= NEW_THRESHOLD, "Precheck: Owner count after adding must be >= NEW_THRESHOLD");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        // Verify new signer was added
        require(IGnosisSafe(SECURITY_COUNCIL).isOwner(NEW_SIGNER), "Postcheck: NEW_SIGNER must be an owner");

        // Verify threshold was updated
        require(
            IGnosisSafe(SECURITY_COUNCIL).getThreshold() == NEW_THRESHOLD, "Postcheck: Threshold must be NEW_THRESHOLD"
        );

        // Verify owner count increased by 1
        require(
            IGnosisSafe(SECURITY_COUNCIL).getOwners().length == currentOwnerCount + 1,
            "Postcheck: Owner count must increase by 1"
        );
    }

    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        // Add new signer and set threshold to NEW_THRESHOLD in a single call
        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: SECURITY_COUNCIL,
            data: abi.encodeCall(IGnosisSafe.addOwnerWithThreshold, (NEW_SIGNER, NEW_THRESHOLD)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return SECURITY_COUNCIL;
    }
}
