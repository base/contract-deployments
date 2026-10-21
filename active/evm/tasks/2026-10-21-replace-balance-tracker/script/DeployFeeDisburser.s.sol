// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";

import {FeeDisburser} from "@base-contracts/src/L2/FeeDisburser.sol";

/// @notice Deploys a FeeDisburser implementation on L2 that bridges fees to the new L1 BalanceTracker.
contract DeployFeeDisburser is Script {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address payable internal immutable FEE_DISBURSER;
    address internal immutable BALANCE_TRACKER;
    uint256 internal immutable FEE_DISBURSEMENT_INTERVAL;

    // Deployment output written to addresses.json.
    address public feeDisburserImpl;

    constructor() {
        FEE_DISBURSER = payable(vm.envAddress("FEE_DISBURSER"));
        FEE_DISBURSEMENT_INTERVAL = vm.envUint("FEE_DISBURSEMENT_INTERVAL");
        BALANCE_TRACKER = vm.parseJsonAddress(vm.readFile(vm.envString("ADDRESSES_JSON")), ".balanceTracker");

        require(
            FeeDisburser(FEE_DISBURSER).FEE_DISBURSEMENT_INTERVAL() == FEE_DISBURSEMENT_INTERVAL,
            "interval differs from live FeeDisburser"
        );
    }

    function run() external {
        vm.startBroadcast();
        feeDisburserImpl = address(new FeeDisburser(BALANCE_TRACKER, FEE_DISBURSEMENT_INTERVAL));
        vm.stopBroadcast();

        FeeDisburser impl = FeeDisburser(payable(feeDisburserImpl));
        require(impl.L1_WALLET() == BALANCE_TRACKER, "L1_WALLET mismatch");
        require(impl.FEE_DISBURSEMENT_INTERVAL() == FEE_DISBURSEMENT_INTERVAL, "interval mismatch");
        _checkDisbursement();

        console.log("FeeDisburser implementation:", feeDisburserImpl);
        vm.writeJson(vm.toString(feeDisburserImpl), vm.envString("ADDRESSES_JSON"), ".feeDisburserImplementation");
    }

    /// @dev Runs disburseFees() through the live proxy with the new implementation against the live fee vaults.
    function _checkDisbursement() internal {
        uint256 snapshot = vm.snapshotState();
        FeeDisburser proxy = FeeDisburser(FEE_DISBURSER);
        vm.store(FEE_DISBURSER, IMPLEMENTATION_SLOT, bytes32(uint256(uint160(feeDisburserImpl))));
        uint256 nextDisbursement = proxy.lastDisbursementTime() + FEE_DISBURSEMENT_INTERVAL;
        if (block.timestamp < nextDisbursement) vm.warp(nextDisbursement);
        proxy.disburseFees();
        vm.revertToState(snapshot);
    }
}
