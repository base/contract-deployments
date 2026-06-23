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
/// @notice Transfers ownership/admin of the Base Sepolia Solana bridge contracts from the alias of
///         the old Coinbase L1 multisig to the alias of the new Coinbase L1 multisig.
contract TransferSolanaBridgeOwnership is MultisigScript {
    using AddressAliasHelper for address;

    // Task config from .env.
    address internal ownerSafeEnv;
    address internal newOwnerSafeEnv;
    address internal optimismPortalEnv;
    address internal erc1967FactoryEnv;
    address internal bridgeEnv;
    address internal twinBeaconEnv;
    address internal crossChainErc20BeaconEnv;
    address internal crossChainErc20FactoryEnv;
    address internal bridgeValidatorEnv;
    address internal relayerOrchestratorEnv;
    uint64 internal l2GasLimitEnv;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("OWNER_SAFE");
        newOwnerSafeEnv = vm.envAddress("NEW_OWNER_SAFE");
        optimismPortalEnv = vm.envAddress("OPTIMISM_PORTAL_ADDR");
        erc1967FactoryEnv = vm.envAddress("ERC1967_FACTORY_ADDR");
        bridgeEnv = vm.envAddress("BRIDGE_ADDR");
        twinBeaconEnv = vm.envAddress("TWIN_BEACON_ADDR");
        crossChainErc20BeaconEnv = vm.envAddress("CROSS_CHAIN_ERC20_BEACON_ADDR");
        crossChainErc20FactoryEnv = vm.envAddress("CROSS_CHAIN_ERC20_FACTORY_ADDR");
        bridgeValidatorEnv = vm.envAddress("BRIDGE_VALIDATOR_ADDR");
        relayerOrchestratorEnv = vm.envAddress("RELAYER_ORCHESTRATOR_ADDR");

        uint256 gasLimit = vm.envUint("L2_GAS_LIMIT");
        require(gasLimit <= type(uint64).max, "TransferSolanaBridgeOwnership: L2_GAS_LIMIT too large");
        l2GasLimitEnv = uint64(gasLimit);
    }

    /// @notice Post-check is a no-op because the L1 simulation cannot verify post-deposit L2 state.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {}

    /// @notice Builds the L1 deposit transactions that transfer ownership of each bridge contract on L2.
    /// @dev Each deposit targets the contract (or the ERC1967Factory) directly rather than routing
    ///      through an L2 CBMulticall, so that the L2 msg.sender is the owner safe's alias and the
    ///      onlyOwner / adminOf checks pass.
    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](7);

        address newOwnerAlias = newOwnerSafeEnv.applyL1ToL2Alias();
        bytes memory transferOwnerCalldata = abi.encodeCall(IOwnable.transferOwnership, (newOwnerAlias));

        // Bridge: OwnableRoles functional owner + ERC1967 proxy admin (both currently the old alias).
        calls[0] = _deposit({l2Target: bridgeEnv, l2Calldata: transferOwnerCalldata});
        calls[1] = _deposit({
            l2Target: erc1967FactoryEnv,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (bridgeEnv, newOwnerAlias))
        });

        // Beacons: Solady UpgradeableBeacon owner.
        calls[2] = _deposit({l2Target: twinBeaconEnv, l2Calldata: transferOwnerCalldata});
        calls[3] = _deposit({l2Target: crossChainErc20BeaconEnv, l2Calldata: transferOwnerCalldata});

        // Proxies with no Ownable owner: ERC1967 proxy admin only.
        calls[4] = _deposit({
            l2Target: erc1967FactoryEnv,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (crossChainErc20FactoryEnv, newOwnerAlias))
        });
        calls[5] = _deposit({
            l2Target: erc1967FactoryEnv,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (bridgeValidatorEnv, newOwnerAlias))
        });
        calls[6] = _deposit({
            l2Target: erc1967FactoryEnv,
            l2Calldata: abi.encodeCall(IERC1967Factory.changeAdmin, (relayerOrchestratorEnv, newOwnerAlias))
        });

        return calls;
    }

    /// @notice Wraps an L2 call into an L1 OptimismPortal deposit transaction.
    function _deposit(address l2Target, bytes memory l2Calldata) internal view returns (Call memory) {
        return Call({
            operation: Enum.Operation.Call,
            target: optimismPortalEnv,
            data: abi.encodeCall(IOptimismPortal2.depositTransaction, (l2Target, 0, l2GasLimitEnv, false, l2Calldata)),
            value: 0
        });
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
