// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm, VmSafe} from "forge-std/Vm.sol";

import {IOptimismPortal2} from "interfaces/L1/IOptimismPortal2.sol";
import {IProxy} from "interfaces/universal/IProxy.sol";
import {AddressAliasHelper} from "@base-contracts/src/vendor/AddressAliasHelper.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

/// @dev FeeDisburser is compiled with 0.8.25, so this script reads it through a minimal interface.
interface IFeeDisburser {
    function L1_WALLET() external view returns (address);
    function FEE_DISBURSEMENT_INTERVAL() external view returns (uint256);
    function lastDisbursementTime() external view returns (uint256);
}

/// @notice Upgrades the L2 FeeDisburser to bridge to the new L1 BalanceTracker and moves its admin to the
///         alias of NEW_ADMIN. The current admin is the alias of OWNER_SAFE, so both calls are L1 deposits.
contract UpgradeFeeDisburser is MultisigScript {
    // Each deposit calls the FeeDisburser proxy directly so it sees the aliased owner. The L1 simulation cannot
    // execute deposits, so the post-check replays them on an L2 fork in order.
    uint64 internal constant L2_GAS_LIMIT = 100_000;

    address internal immutable OWNER_SAFE;
    address internal immutable NEW_ADMIN;
    address internal immutable NEW_ADMIN_L2_ALIAS;
    address internal immutable OPTIMISM_PORTAL;
    address internal immutable FEE_DISBURSER;
    address internal immutable FEE_DISBURSER_IMPL;
    address internal immutable BALANCE_TRACKER;
    uint256 internal immutable L2_FORK;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        NEW_ADMIN = vm.envAddress("NEW_ADMIN");
        NEW_ADMIN_L2_ALIAS = vm.envAddress("NEW_ADMIN_L2_ALIAS");
        OPTIMISM_PORTAL = vm.envAddress("OPTIMISM_PORTAL");
        FEE_DISBURSER = vm.envAddress("FEE_DISBURSER");
        FEE_DISBURSER_IMPL = vm.envAddress("NEW_FEE_DISBURSER_IMPL");
        BALANCE_TRACKER = vm.envAddress("NEW_BALANCE_TRACKER");
        L2_FORK = vm.createFork(vm.envString("L2_RPC_URL"));

        require(
            NEW_ADMIN_L2_ALIAS == AddressAliasHelper.applyL1ToL2Alias(NEW_ADMIN),
            "NEW_ADMIN_L2_ALIAS is not the alias of NEW_ADMIN"
        );
    }

    function setUp() public {
        require(!IOptimismPortal2(payable(OPTIMISM_PORTAL)).paused(), "optimism portal paused");
        require(BALANCE_TRACKER.code.length > 0, "BalanceTracker not deployed");
        require(NEW_ADMIN.code.length > 0, "NEW_ADMIN has no code");
        require(_admin(BALANCE_TRACKER) == NEW_ADMIN, "BalanceTracker admin is not NEW_ADMIN");

        uint256 l1Fork = vm.activeFork();
        vm.selectFork(L2_FORK);
        require(_admin(FEE_DISBURSER) == AddressAliasHelper.applyL1ToL2Alias(OWNER_SAFE), "unexpected L2 admin");
        require(FEE_DISBURSER_IMPL.code.length > 0, "FeeDisburser implementation not deployed");
        require(IFeeDisburser(FEE_DISBURSER_IMPL).L1_WALLET() == BALANCE_TRACKER, "implementation L1_WALLET mismatch");
        require(
            IFeeDisburser(FEE_DISBURSER_IMPL).FEE_DISBURSEMENT_INTERVAL()
                == IFeeDisburser(FEE_DISBURSER).FEE_DISBURSEMENT_INTERVAL(),
            "implementation interval mismatch"
        );
        vm.selectFork(l1Fork);
    }

    function _buildCalls() internal view override returns (Call[] memory calls) {
        bytes[] memory l2Calls = _l2Calls();
        calls = new Call[](l2Calls.length);
        for (uint256 i; i < l2Calls.length; i++) {
            calls[i] = Call({
                operation: Enum.Operation.Call,
                target: OPTIMISM_PORTAL,
                data: abi.encodeCall(
                    IOptimismPortal2.depositTransaction, (FEE_DISBURSER, 0, L2_GAS_LIMIT, false, l2Calls[i])
                ),
                value: 0
            });
        }
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        _assertDeposits(accesses);

        uint256 l1Fork = vm.activeFork();
        vm.selectFork(L2_FORK);
        uint256 lastDisbursementTime = IFeeDisburser(FEE_DISBURSER).lastDisbursementTime();

        bytes[] memory l2Calls = _l2Calls();
        for (uint256 i; i < l2Calls.length; i++) {
            vm.prank(AddressAliasHelper.applyL1ToL2Alias(OWNER_SAFE));
            (bool success,) = FEE_DISBURSER.call{gas: L2_GAS_LIMIT}(l2Calls[i]);
            require(success, "L2 call reverted");
        }

        require(_implementation(FEE_DISBURSER) == FEE_DISBURSER_IMPL, "implementation not upgraded");
        require(_admin(FEE_DISBURSER) == AddressAliasHelper.applyL1ToL2Alias(NEW_ADMIN), "admin not moved");
        require(IFeeDisburser(FEE_DISBURSER).L1_WALLET() == BALANCE_TRACKER, "L1_WALLET mismatch");
        require(
            IFeeDisburser(FEE_DISBURSER).lastDisbursementTime() == lastDisbursementTime, "disbursement time changed"
        );
        vm.selectFork(l1Fork);
    }

    function _assertDeposits(Vm.AccountAccess[] memory accesses) internal view {
        uint256 deposits;
        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory access = accesses[i];
            if (access.kind != VmSafe.AccountAccessKind.Call || access.account != OPTIMISM_PORTAL) continue;
            if (access.data.length < 4 || bytes4(access.data) != IOptimismPortal2.depositTransaction.selector) {
                continue;
            }
            require(access.accessor == OWNER_SAFE, "deposit not sent by OWNER_SAFE");
            require(!access.reverted, "deposit reverted");
            deposits++;
        }
        require(deposits == 2, "unexpected deposit count");
    }

    function _l2Calls() internal view returns (bytes[] memory calls) {
        calls = new bytes[](2);
        calls[0] = abi.encodeCall(IProxy.upgradeTo, (FEE_DISBURSER_IMPL));
        calls[1] = abi.encodeCall(IProxy.changeAdmin, (NEW_ADMIN_L2_ALIAS));
    }

    function _admin(address proxy) internal returns (address) {
        vm.prank(address(0));
        return IProxy(payable(proxy)).admin();
    }

    function _implementation(address proxy) internal returns (address) {
        vm.prank(address(0));
        return IProxy(payable(proxy)).implementation();
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
