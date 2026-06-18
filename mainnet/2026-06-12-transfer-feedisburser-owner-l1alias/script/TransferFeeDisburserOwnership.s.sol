// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IOptimismPortal2} from "@base-contracts/interfaces/L1/IOptimismPortal2.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {AddressAliasHelper} from "@base-contracts/src/vendor/AddressAliasHelper.sol";

/// @title TransferFeeDisburserOwnership
/// @notice Transfers the Base mainnet FeeDisburser proxy owner to the alias of the new Coinbase L1 multisig.
contract TransferFeeDisburserOwnership is MultisigScript {
    using AddressAliasHelper for address;

    /// @notice L1 Safe that currently owns the FeeDisburser proxy through its L2 alias.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    /// @notice L1 Safe that should own the FeeDisburser proxy through its L2 alias.
    address public immutable NEW_OWNER_SAFE = vm.envAddress("NEW_OWNER_SAFE");

    /// @notice Expected L2 alias of OWNER_SAFE.
    address public immutable CURRENT_OWNER_ALIAS = vm.envAddress("CURRENT_OWNER_ALIAS");

    /// @notice Expected L2 alias of NEW_OWNER_SAFE.
    address public immutable NEW_OWNER_ALIAS = vm.envAddress("NEW_OWNER_ALIAS");

    /// @notice OptimismPortal2 contract on L1 used for deposit transactions.
    address public immutable OPTIMISM_PORTAL = vm.envAddress("OPTIMISM_PORTAL_ADDR");

    /// @notice FeeDisburser proxy contract on Base mainnet L2.
    address public immutable FEE_DISBURSER_PROXY = vm.envAddress("FEE_DISBURSER_ADDR");

    /// @notice Gas limit for the L2 deposit transaction.
    uint64 public immutable L2_GAS_LIMIT;

    constructor() {
        uint256 gasLimit = vm.envUint("L2_GAS_LIMIT");
        require(gasLimit <= type(uint64).max, "TransferFeeDisburserOwnership: L2_GAS_LIMIT too large");
        L2_GAS_LIMIT = uint64(gasLimit);

        require(
            OWNER_SAFE.applyL1ToL2Alias() == CURRENT_OWNER_ALIAS,
            "TransferFeeDisburserOwnership: incorrect current owner alias"
        );
        require(
            NEW_OWNER_SAFE.applyL1ToL2Alias() == NEW_OWNER_ALIAS,
            "TransferFeeDisburserOwnership: incorrect new owner alias"
        );
    }

    /// @notice Post-check is a no-op because the L1 simulation cannot verify post-deposit L2 state.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {}

    /// @notice Builds the L1 deposit transaction that calls changeAdmin on the FeeDisburser proxy on L2.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        bytes memory transferOwnerCalldata = abi.encodeCall(Proxy.changeAdmin, (NEW_OWNER_ALIAS));

        // A batched L2 route through CBMulticall would call the proxy with CBMulticall
        // as msg.sender. This proxy admin transfer must be called directly by
        // OWNER_SAFE's L2 alias, so the deposit targets the proxy itself.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: OPTIMISM_PORTAL,
            data: abi.encodeCall(
                IOptimismPortal2.depositTransaction,
                (FEE_DISBURSER_PROXY, 0, L2_GAS_LIMIT, false, transferOwnerCalldata)
            ),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
