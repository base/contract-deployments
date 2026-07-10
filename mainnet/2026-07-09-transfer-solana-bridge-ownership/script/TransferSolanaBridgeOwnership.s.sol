// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IOptimismPortal2} from "@base-contracts/interfaces/L1/IOptimismPortal2.sol";
import {AddressAliasHelper} from "@base-contracts/src/vendor/AddressAliasHelper.sol";

/// @notice Minimal interface for Solady Ownable / OwnableRoles / UpgradeableBeacon ownership transfer.
interface IOwnable {
    function transferOwnership(address newOwner) external;
}

/// @notice Minimal interface for the shared Solady ERC1967Factory proxy-admin transfer.
interface IERC1967Factory {
    function changeAdmin(address proxy, address admin) external;
}

/// @title TransferSolanaBridgeOwnership
/// @notice Transfers ownership/admin of the Base mainnet Solana bridge contracts from the alias of
///         the old Coinbase L1 multisig to the alias of the new Coinbase L1 multisig.
contract TransferSolanaBridgeOwnership is MultisigScript {
    using AddressAliasHelper for address;

    /// @notice L1 Safe that currently owns the bridge contracts through its L2 alias.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    /// @notice L1 Safe that should own the bridge contracts through its L2 alias.
    address public immutable NEW_OWNER_SAFE = vm.envAddress("NEW_OWNER_SAFE");

    /// @notice Expected L2 alias of OWNER_SAFE.
    address public immutable CURRENT_OWNER_ALIAS = vm.envAddress("CURRENT_OWNER_ALIAS");

    /// @notice Expected L2 alias of NEW_OWNER_SAFE.
    address public immutable NEW_OWNER_ALIAS = vm.envAddress("NEW_OWNER_ALIAS");

    /// @notice OptimismPortal2 contract on L1 used for deposit transactions.
    address public immutable OPTIMISM_PORTAL = vm.envAddress("OPTIMISM_PORTAL_ADDR");

    /// @notice Shared Solady ERC1967Factory that holds proxy admins.
    address public immutable ERC1967_FACTORY = vm.envAddress("ERC1967_FACTORY_ADDR");

    /// @notice Solana bridge proxy on Base mainnet L2.
    address public immutable BRIDGE = vm.envAddress("BRIDGE_ADDR");

    /// @notice Twin UpgradeableBeacon on Base mainnet L2.
    address public immutable TWIN_BEACON = vm.envAddress("TWIN_BEACON_ADDR");

    /// @notice CrossChainERC20 UpgradeableBeacon on Base mainnet L2.
    address public immutable CROSS_CHAIN_ERC20_BEACON = vm.envAddress("CROSS_CHAIN_ERC20_BEACON_ADDR");

    /// @notice CrossChainERC20Factory proxy on Base mainnet L2.
    address public immutable CROSS_CHAIN_ERC20_FACTORY = vm.envAddress("CROSS_CHAIN_ERC20_FACTORY_ADDR");

    /// @notice BridgeValidator proxy on Base mainnet L2.
    address public immutable BRIDGE_VALIDATOR = vm.envAddress("BRIDGE_VALIDATOR_ADDR");

    /// @notice RelayerOrchestrator proxy on Base mainnet L2.
    address public immutable RELAYER_ORCHESTRATOR = vm.envAddress("RELAYER_ORCHESTRATOR_ADDR");

    /// @notice Gas limit for each L2 deposit transaction.
    uint64 public immutable L2_GAS_LIMIT;

    constructor() {
        uint256 gasLimit = vm.envUint("L2_GAS_LIMIT");
        require(gasLimit <= type(uint64).max, "TransferSolanaBridgeOwnership: L2_GAS_LIMIT too large");
        L2_GAS_LIMIT = uint64(gasLimit);

        require(
            OWNER_SAFE.applyL1ToL2Alias() == CURRENT_OWNER_ALIAS,
            "TransferSolanaBridgeOwnership: incorrect current owner alias"
        );
        require(
            NEW_OWNER_SAFE.applyL1ToL2Alias() == NEW_OWNER_ALIAS,
            "TransferSolanaBridgeOwnership: incorrect new owner alias"
        );
    }

    /// @notice Post-check is a no-op because the L1 simulation cannot verify post-deposit L2 state.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {}

    /// @notice Builds the L1 deposit transactions that transfer ownership of each bridge contract on L2.
    /// @dev Each deposit targets the contract (or the ERC1967Factory) directly rather than routing
    ///      through an L2 CBMulticall, so that the L2 msg.sender is the owner safe's alias and the
    ///      onlyOwner / adminOf checks pass.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](7);

        bytes memory transferOwnerCalldata = abi.encodeCall(IOwnable.transferOwnership, (NEW_OWNER_ALIAS));

        // Bridge: OwnableRoles functional owner + ERC1967 proxy admin (both currently the old alias).
        calls[0] = _deposit({l2Target: BRIDGE, l2Calldata: transferOwnerCalldata});
        calls[1] = _deposit({
            l2Target: ERC1967_FACTORY,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (BRIDGE, NEW_OWNER_ALIAS))
        });

        // Beacons: Solady UpgradeableBeacon owner.
        calls[2] = _deposit({l2Target: TWIN_BEACON, l2Calldata: transferOwnerCalldata});
        calls[3] = _deposit({l2Target: CROSS_CHAIN_ERC20_BEACON, l2Calldata: transferOwnerCalldata});

        // Proxies with no Ownable owner: ERC1967 proxy admin only.
        calls[4] = _deposit({
            l2Target: ERC1967_FACTORY,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (CROSS_CHAIN_ERC20_FACTORY, NEW_OWNER_ALIAS))
        });
        calls[5] = _deposit({
            l2Target: ERC1967_FACTORY,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (BRIDGE_VALIDATOR, NEW_OWNER_ALIAS))
        });
        calls[6] = _deposit({
            l2Target: ERC1967_FACTORY,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (RELAYER_ORCHESTRATOR, NEW_OWNER_ALIAS))
        });

        return calls;
    }

    /// @notice Wraps an L2 call into an L1 OptimismPortal deposit transaction.
    function _deposit(address l2Target, bytes memory l2Calldata) internal view returns (Call memory) {
        return Call({
            operation: Enum.Operation.Call,
            target: OPTIMISM_PORTAL,
            data: abi.encodeCall(IOptimismPortal2.depositTransaction, (l2Target, 0, L2_GAS_LIMIT, false, l2Calldata)),
            value: 0
        });
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
