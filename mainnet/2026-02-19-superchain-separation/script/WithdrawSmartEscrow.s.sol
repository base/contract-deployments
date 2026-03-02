// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

interface ISmartEscrow {
    function withdrawUnvestedTokens() external;
    function contractTerminated() external view returns (bool);
}

/// @title WithdrawSmartEscrow
/// @notice Script to withdraw unvested tokens from the SmartEscrow contract via a multisig transaction.
///         The caller must have the DEFAULT_ADMIN_ROLE on the SmartEscrow contract.
///         The contract must be terminated before calling this function.
///         This withdraws all remaining OP tokens to the benefactor address.
contract WithdrawSmartEscrow is MultisigScript {
    /// @notice OP token contract address.
    IERC20 public constant OP_TOKEN = IERC20(0x4200000000000000000000000000000000000042);

    /// @notice Storage slot for the `contractTerminated` variable in the SmartEscrow contract.
    /// @dev    This slot was determined using `forge inspect SmartEscrow storage-layout`.
    bytes32 public constant CONTRACT_TERMINATED_SLOT = bytes32(uint256(6));

    /// @notice The Safe address that has the DEFAULT_ADMIN_ROLE on the SmartEscrow contract.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE_ON_OP");

    /// @notice The SmartEscrow contract address to withdraw from.
    address public immutable SMART_ESCROW = vm.envAddress("SMART_ESCROW");

    /// @notice Verifies that the SmartEscrow contract's OP token balance is zero after withdrawal.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(ISmartEscrow(SMART_ESCROW).contractTerminated(), "Postcheck: SmartEscrow contract must be terminated");
        require(OP_TOKEN.balanceOf(SMART_ESCROW) == 0, "Postcheck: SmartEscrow OP token balance is not zero");
    }

    /// @notice Builds the call to SmartEscrow.withdrawUnvestedTokens().
    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: SMART_ESCROW,
            data: abi.encodeCall(ISmartEscrow.withdrawUnvestedTokens, ()),
            value: 0
        });

        return calls;
    }

    function _simulationOverrides()
        internal
        view
        virtual
        override
        returns (Simulation.StateOverride[] memory overrides_)
    {
        // If the contract is not yet terminated, override the storage slot to simulate termination.
        if (!ISmartEscrow(SMART_ESCROW).contractTerminated()) {
            Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);
            storageOverrides[0] = Simulation.StorageOverride({
                key: CONTRACT_TERMINATED_SLOT,
                value: bytes32(uint256(1)) // true
            });

            overrides_ = new Simulation.StateOverride[](1);
            overrides_[0] = Simulation.StateOverride(SMART_ESCROW, storageOverrides);
        }
    }

    /// @notice Returns the Safe address that will execute this transaction.
    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
