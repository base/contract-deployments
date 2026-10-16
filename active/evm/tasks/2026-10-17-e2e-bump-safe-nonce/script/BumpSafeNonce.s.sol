// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface ISafe {
    function nonce() external view returns (uint256);
}

/// @notice Test task for the signing tool. The Base multisig calls its own `nonce()` view, so the only
///         state change is the Safe nonce increment that every executed Safe transaction makes.
/// @dev Lives on the long-lived `test/e2e` branch only. Never merge into main.
contract BumpSafeNonce is MultisigScript {
    address internal immutable ownerSafe;

    /// @dev Live nonce captured at construction and re-asserted after execution.
    uint256 internal immutable startNonce;

    constructor() {
        ownerSafe = vm.envAddress("CB_MULTISIG");
        startNonce = ISafe(ownerSafe).nonce();
    }

    function setUp() public view {
        require(ownerSafe.code.length > 0, "CB_MULTISIG has no code");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: ownerSafe,
            data: abi.encodeCall(ISafe.nonce, ()),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        require(ISafe(ownerSafe).nonce() == startNonce + 1, "nonce not bumped by exactly one");

        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory access = accesses[i];
            require(access.oldBalance == access.newBalance, "unexpected balance change");
            for (uint256 j; j < access.storageAccesses.length; j++) {
                Vm.StorageAccess memory s = access.storageAccesses[j];
                if (!s.isWrite || s.reverted || s.previousValue == s.newValue) continue;
                require(
                    s.account == ownerSafe && s.slot == Simulation.SAFE_NONCE_SLOT,
                    "unexpected storage write"
                );
            }
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
