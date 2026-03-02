// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @title UpdateProxyAdminOwnerSigners
/// @notice Swaps OP_SAFE for SECURITY_COUNCIL as an owner on the ProxyAdmin owner Safe.
/// @dev This script expects the Safe to have exactly 2 owners and threshold of 2 before and after the swap.
contract UpdateProxyAdminOwnerSigners is MultisigScript {
    /// @notice Sentinel address used by Safe's linked list implementation.
    address internal constant SENTINEL = address(0x1);

    /// @notice Expected owner count before and after the swap.
    uint256 internal constant EXPECTED_OWNER_COUNT = 2;

    /// @notice The Safe whose signers are being updated.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    /// @notice The OP signer Safe to be removed as an owner.
    address public immutable OP_SAFE = vm.envAddress("OP_SIGNER_SAFE_ADDR");

    /// @notice The security council Safe to be added as an owner.
    address public immutable SECURITY_COUNCIL = vm.envAddress("CB_SC_SAFE_ADDR");

    /// @notice The previous owner in Safe's linked list, needed for swapOwner.
    address public prevOwner = SENTINEL;

    function setUp() external {
        // Prechecks: Verify initial state
        require(IGnosisSafe(OWNER_SAFE).isOwner(OP_SAFE), "Precheck: OP_SAFE must be an owner");
        require(
            !IGnosisSafe(OWNER_SAFE).isOwner(SECURITY_COUNCIL),
            "Precheck: SECURITY_COUNCIL must not already be an owner"
        );
        require(
            IGnosisSafe(OWNER_SAFE).getOwners().length == EXPECTED_OWNER_COUNT,
            "Precheck: Must have EXPECTED_OWNER_COUNT owners"
        );

        // Find prevOwner for OP_SAFE in Safe's linked list.
        // Safe's getOwners() returns owners in linked list order.
        // The first owner has SENTINEL (0x1) as its prevOwner.
        address[] memory owners = IGnosisSafe(OWNER_SAFE).getOwners();

        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == OP_SAFE) break;
            prevOwner = owners[i];
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(IGnosisSafe(OWNER_SAFE).isOwner(SECURITY_COUNCIL), "Postcheck: SECURITY_COUNCIL must be an owner");
        require(!IGnosisSafe(OWNER_SAFE).isOwner(OP_SAFE), "Postcheck: OP_SAFE must be removed");
        require(
            IGnosisSafe(OWNER_SAFE).getOwners().length == EXPECTED_OWNER_COUNT,
            "Postcheck: Must have EXPECTED_OWNER_COUNT owners"
        );
    }

    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: OWNER_SAFE,
            data: abi.encodeCall(IGnosisSafe.swapOwner, (prevOwner, OP_SAFE, SECURITY_COUNCIL)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
