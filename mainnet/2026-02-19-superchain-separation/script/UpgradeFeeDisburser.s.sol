// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface IProxy {
    function upgradeTo(address newImplementation) external;
}

/// @title UpgradeFeeDisburser
/// @notice Script to upgrade the FeeDisburser proxy on L2 via a deposit transaction from L1.
///         The FeeDisburser proxy is owned by CB_NESTED_SAFE_ADDR on L1, so this upgrade
///         must be executed as a deposit transaction through OptimismPortal2.
contract UpgradeFeeDisburser is MultisigScript {
    /// @notice The L1 Safe that owns the FeeDisburser proxy (aliased address is the admin).
    address public immutable OWNER_SAFE = vm.envAddress("CB_NESTED_SAFE_ADDR");

    /// @notice The OptimismPortal2 contract on L1 used for deposit transactions.
    address public immutable OPTIMISM_PORTAL = vm.envAddress("OPTIMISM_PORTAL_ADDR");

    /// @notice The FeeDisburser proxy contract on L2.
    address public immutable FEE_DISBURSER_PROXY = vm.envAddress("FEE_DISBURSER_ADDR");

    /// @notice The new FeeDisburser implementation contract on L2.
    address public immutable FEE_DISBURSER_IMPL = vm.envAddress("FEE_DISBURSER_IMPL_ADDR");

    /// @notice Post-check is a no-op since we cannot verify L2 state from L1 simulation.
    ///         The upgrade result should be verified on L2 after the deposit transaction is processed.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {}

    /// @notice Builds the call to OptimismPortal2.depositTransaction that will upgrade
    ///         the FeeDisburser proxy on L2.
    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        // Build the upgradeTo calldata to call directly on the FeeDisburser proxy
        bytes memory upgradeCalldata = abi.encodeCall(IProxy.upgradeTo, (FEE_DISBURSER_IMPL));

        // Parameters for the deposit transaction
        address to = FEE_DISBURSER_PROXY;
        uint256 value = 0;
        uint64 gasLimit = 100_000; // Sufficient gas for proxy upgrade
        bool isCreation = false;

        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: OPTIMISM_PORTAL,
            data: abi.encodeCall(
                IOptimismPortal2.depositTransaction, (to, value, gasLimit, isCreation, upgradeCalldata)
            ),
            value: 0
        });

        return calls;
    }

    /// @notice Returns the Safe address that will execute this transaction on L1.
    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
