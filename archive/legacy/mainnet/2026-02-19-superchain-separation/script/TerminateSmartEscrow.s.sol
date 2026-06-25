// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

interface ISmartEscrow {
    function terminate() external;
    function contractTerminated() external view returns (bool);
}

/// @title TerminateSmartEscrow
/// @notice Script to terminate the SmartEscrow contract via a multisig transaction.
///         The caller must have the TERMINATOR_ROLE on the SmartEscrow contract.
///         Termination releases any vested tokens to the beneficiary before setting
///         the contract to a terminated state.
contract TerminateSmartEscrow is MultisigScript {
    /// @notice The Safe address that has the TERMINATOR_ROLE on the SmartEscrow contract.
    address public immutable OWNER_SAFE = vm.envAddress("CB_SAFE_ON_OP");

    /// @notice The SmartEscrow contract address to terminate.
    address public immutable SMART_ESCROW = vm.envAddress("SMART_ESCROW");

    /// @notice Verifies that the SmartEscrow contract was successfully terminated.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(ISmartEscrow(SMART_ESCROW).contractTerminated(), "Postcheck: SmartEscrow contract was not terminated");
    }

    /// @notice Builds the call to SmartEscrow.terminate().
    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: SMART_ESCROW,
            data: abi.encodeCall(ISmartEscrow.terminate, ()),
            value: 0
        });

        return calls;
    }

    /// @notice Returns the Safe address that will execute this transaction.
    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
