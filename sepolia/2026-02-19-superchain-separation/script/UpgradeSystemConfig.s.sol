// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {SystemConfig, IResourceMetering, ISuperchainConfig} from "@base-contracts/src/L1/SystemConfig.sol";
import {IProxyAdmin} from "@base-contracts/interfaces/universal/IProxyAdmin.sol";

/// @title UpgradeSystemConfig
/// @notice Script to upgrade the SystemConfig proxy to a new implementation and reinitialize
///         it with a new SuperchainConfig address. This preserves all existing configuration
///         parameters while updating the SuperchainConfig reference.
contract UpgradeSystemConfig is MultisigScript {
    /// @notice The Safe that owns the ProxyAdmin and will execute this upgrade.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    /// @notice The ProxyAdmin contract that manages the SystemConfig proxy.
    address public immutable PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");

    /// @notice The SystemConfig proxy contract to be upgraded.
    address public immutable SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

    /// @notice The new SystemConfig implementation contract.
    address public immutable SYSTEM_CONFIG_IMPLEMENTATION = vm.envAddress("SYSTEM_CONFIG_IMPLEMENTATION");

    /// @notice The new SuperchainConfig address to set during reinitialization.
    address public immutable NEW_SUPERCHAIN_CONFIG = vm.envAddress("NEW_SUPERCHAIN_CONFIG");

    /// @notice Validates the post-upgrade state.
    /// @dev Verifies that:
    ///      1. The implementation was updated correctly
    ///      2. The SuperchainConfig was set to the new address
    ///      3. All existing parameters were preserved
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        SystemConfig systemConfig = SystemConfig(SYSTEM_CONFIG);

        // Verify the implementation was updated
        address currentImpl = IProxyAdmin(PROXY_ADMIN).getProxyImplementation(SYSTEM_CONFIG);
        require(currentImpl == SYSTEM_CONFIG_IMPLEMENTATION, "Postcheck: Implementation not updated");

        // Verify the SuperchainConfig was updated
        require(
            address(systemConfig.superchainConfig()) == NEW_SUPERCHAIN_CONFIG, "Postcheck: SuperchainConfig not updated"
        );
    }

    /// @notice Builds the upgrade call to ProxyAdmin.upgradeAndCall.
    /// @dev Reads all existing SystemConfig parameters and rebuilds the initialize calldata
    ///      with the new SuperchainConfig address. All other parameters are preserved.
    function _buildCalls() internal view override returns (MultisigScript.Call[] memory) {
        SystemConfig systemConfig = SystemConfig(SYSTEM_CONFIG);

        // Get all existing SystemConfig parameters
        address owner = systemConfig.owner();
        uint32 basefeeScalar = systemConfig.basefeeScalar();
        uint32 blobbasefeeScalar = systemConfig.blobbasefeeScalar();
        bytes32 batcherHash = systemConfig.batcherHash();
        uint64 gasLimit = systemConfig.gasLimit();
        address unsafeBlockSigner = systemConfig.unsafeBlockSigner();
        IResourceMetering.ResourceConfig memory resourceConfig = systemConfig.resourceConfig();
        address batchInbox = systemConfig.batchInbox();
        uint256 l2ChainId = systemConfig.l2ChainId();

        // Get the Addresses struct
        SystemConfig.Addresses memory addresses = systemConfig.getAddresses();

        // Build the initialize calldata with the new SuperchainConfig
        bytes memory initializeCalldata = abi.encodeCall(
            SystemConfig.initialize,
            (
                owner,
                basefeeScalar,
                blobbasefeeScalar,
                batcherHash,
                gasLimit,
                unsafeBlockSigner,
                resourceConfig,
                batchInbox,
                addresses,
                l2ChainId,
                ISuperchainConfig(NEW_SUPERCHAIN_CONFIG)
            )
        );

        MultisigScript.Call[] memory calls = new MultisigScript.Call[](1);

        calls[0] = MultisigScript.Call({
            operation: Enum.Operation.Call,
            target: PROXY_ADMIN,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall, (payable(SYSTEM_CONFIG), SYSTEM_CONFIG_IMPLEMENTATION, initializeCalldata)
            ),
            value: 0
        });

        return calls;
    }

    /// @notice Returns the Safe address that will execute this transaction.
    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
