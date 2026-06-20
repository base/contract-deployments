// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @title UpdateCBSafeSigners
/// @notice Updates the CB signer safe to replace nested safe signers with individual EOAs.
/// @dev Execution order:
///      1. Remove SECURITY_COUNCIL from OWNER_SAFE (threshold temporarily set to 1)
///      2. Add each CB EOA from CB_NESTED_SAFE as direct signers (threshold stays at 1)
///      3. Remove CB_NESTED_SAFE and set final threshold to FINAL_THRESHOLD
contract UpdateCBSafeSigners is MultisigScript {
    /// @notice Sentinel address used by Safe's linked list implementation.
    address internal constant SENTINEL = address(0x1);

    /// @notice Interim threshold used during owner modifications.
    uint256 internal constant INTERIM_THRESHOLD = 1;

    /// @notice Final threshold after all owner modifications are complete.
    uint256 public constant FINAL_THRESHOLD = 3;

    /// @notice The Safe whose signers are being updated.
    address public immutable OWNER_SAFE = vm.envAddress("CB_SIGNER_SAFE_ADDR");

    /// @notice The security council Safe to be removed as a signer.
    address public immutable SECURITY_COUNCIL = vm.envAddress("CB_SC_SAFE_ADDR");

    /// @notice The nested Safe whose EOA owners will become direct signers.
    address public immutable CB_NESTED_SAFE = vm.envAddress("CB_NESTED_SAFE_ADDR");

    /// @notice The previous owner in Safe's linked list, needed for removeOwner.
    address public prevOwnerOfSecurityCouncil = SENTINEL;

    /// @notice The EOA addresses from CB_NESTED_SAFE that will become direct signers.
    address[] public cbEoas;

    function setUp() external {
        // Prechecks: Verify initial state
        require(IGnosisSafe(OWNER_SAFE).isOwner(SECURITY_COUNCIL), "Precheck: SECURITY_COUNCIL must be an owner");
        require(IGnosisSafe(OWNER_SAFE).isOwner(CB_NESTED_SAFE), "Precheck: CB_NESTED_SAFE must be an owner");

        // Find prevOwner for SECURITY_COUNCIL in Safe's linked list.
        // Safe's getOwners() returns owners in linked list order.
        // The first owner has SENTINEL (0x1) as its prevOwner.
        address[] memory owners = IGnosisSafe(OWNER_SAFE).getOwners();

        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == SECURITY_COUNCIL) break;
            prevOwnerOfSecurityCouncil = owners[i];
        }

        // Get EOAs from nested safe to add as direct signers
        cbEoas = IGnosisSafe(CB_NESTED_SAFE).getOwners();
        require(cbEoas.length > 0, "Precheck: CB_NESTED_SAFE must have at least one owner");
        require(cbEoas.length >= FINAL_THRESHOLD, "Precheck: CB_NESTED_SAFE must have at least FINAL_THRESHOLD owners");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        // Verify removed signers
        require(!IGnosisSafe(OWNER_SAFE).isOwner(SECURITY_COUNCIL), "Postcheck: SECURITY_COUNCIL must be removed");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(CB_NESTED_SAFE), "Postcheck: CB_NESTED_SAFE must be removed");

        // Verify all EOAs are now direct signers
        for (uint256 i = 0; i < cbEoas.length; i++) {
            require(IGnosisSafe(OWNER_SAFE).isOwner(cbEoas[i]), "Postcheck: CB EOA must be an owner");
        }

        // Verify threshold
        require(
            IGnosisSafe(OWNER_SAFE).getThreshold() == FINAL_THRESHOLD, "Postcheck: Threshold must be FINAL_THRESHOLD"
        );
    }

    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        // Total calls: 1 (remove SECURITY_COUNCIL) + cbEoas.length (add EOAs) + 1 (remove CB_NESTED_SAFE)
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](2 + cbEoas.length);

        // Step 1: Remove SECURITY_COUNCIL, set threshold to 1
        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: OWNER_SAFE,
            data: abi.encodeCall(
                IGnosisSafe.removeOwner, (prevOwnerOfSecurityCouncil, SECURITY_COUNCIL, INTERIM_THRESHOLD)
            ),
            value: 0
        });

        // Step 2: Add each CB EOA as a direct signer (keep threshold at 1)
        // Note: addOwnerWithThreshold adds new owners to the FRONT of Safe's linked list.
        // After adding cbEoas[0..n-1], the order will be:
        //   SENTINEL -> cbEoas[n-1] -> ... -> cbEoas[0] -> CB_NESTED_SAFE -> ...
        // Therefore, cbEoas[0] will be the prevOwner of CB_NESTED_SAFE.
        for (uint256 i = 0; i < cbEoas.length; i++) {
            calls[i + 1] = MultisigScript.Call({
                operation: Enum.Operation.Call,
                target: OWNER_SAFE,
                data: abi.encodeCall(IGnosisSafe.addOwnerWithThreshold, (cbEoas[i], INTERIM_THRESHOLD)),
                value: 0
            });
        }

        // Step 3: Remove CB_NESTED_SAFE and set final threshold
        // cbEoas[0] is the prevOwner because it was added first and is now
        // immediately before CB_NESTED_SAFE in the linked list.
        calls[calls.length - 1] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: OWNER_SAFE,
            data: abi.encodeCall(IGnosisSafe.removeOwner, (cbEoas[0], CB_NESTED_SAFE, FINAL_THRESHOLD)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
