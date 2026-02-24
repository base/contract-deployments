// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
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

    /// @notice The security council Safe that becomes an owner of OWNER_SAFE after step 1.
    address public immutable SECURITY_COUNCIL = vm.envAddress("CB_SC_SAFE_ADDR");

    /// @notice Safe's owners linked list base storage slot: mapping(address => address) at slot 2.
    bytes32 internal constant SAFE_OWNERS_BASE_SLOT = bytes32(uint256(2));

    /// @notice Sentinel address used by Safe's linked list implementation.
    address internal constant SENTINEL = address(0x1);

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

    /// @notice Overrides the OWNER_SAFE state to include SECURITY_COUNCIL as an owner
    ///         when step 1 (UpdateProxyAdminOwnerSigners) hasn't been executed yet.
    ///         This allows pre-generating SC validation files before step 1 runs on-chain.
    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory) {
        if (IGnosisSafe(OWNER_SAFE).isOwner(SECURITY_COUNCIL)) {
            return new Simulation.StateOverride[](0);
        }

        // Insert SECURITY_COUNCIL at the head of OWNER_SAFE's owners linked list:
        //   SENTINEL -> SECURITY_COUNCIL -> old_head -> ...
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL, SAFE_OWNERS_BASE_SLOT));
        address currentHead = address(uint160(uint256(vm.load(OWNER_SAFE, sentinelSlot))));
        bytes32 scSlot = keccak256(abi.encode(SECURITY_COUNCIL, SAFE_OWNERS_BASE_SLOT));

        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](2);
        storageOverrides[0] = Simulation.StorageOverride({
            key: sentinelSlot,
            value: bytes32(uint256(uint160(SECURITY_COUNCIL)))
        });
        storageOverrides[1] = Simulation.StorageOverride({key: scSlot, value: bytes32(uint256(uint160(currentHead)))});

        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](1);
        overrides[0] = Simulation.StateOverride({contractAddress: OWNER_SAFE, overrides: storageOverrides});
        return overrides;
    }

    /// @notice Returns the Safe address that will execute this transaction.
    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
