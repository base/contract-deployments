// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {FeeDisburser} from "@base-contracts/src/revenue-share/FeeDisburser.sol";

/// @title DeployFeeDisburser
/// @notice Deploys the FeeDisburser contract which collects fees from L2 FeeVaults and bridges them to L1.
/// @dev Required environment variables:
///      - L1_WALLET: The L1 address that will receive bridged fees
///      - FEE_DISBURSEMENT_INTERVAL: Minimum time in seconds between disbursements (must be >= 24 hours)
contract DeployFeeDisburser is Script {
    /// @notice The L1 address that will receive the bridged fees.
    address public immutable L1_WALLET = vm.envAddress("BALANCE_TRACKER");

    /// @notice The minimum time in seconds between fee disbursements.
    uint256 public immutable FEE_DISBURSEMENT_INTERVAL = vm.envUint("FEE_DISBURSEMENT_INTERVAL");

    function run() external {
        vm.startBroadcast();

        FeeDisburser feeDisburser = new FeeDisburser(L1_WALLET, FEE_DISBURSEMENT_INTERVAL);

        console.log("FeeDisburser deployed at:", address(feeDisburser));
        console.log("  L1_WALLET:", L1_WALLET);
        console.log("  FEE_DISBURSEMENT_INTERVAL:", FEE_DISBURSEMENT_INTERVAL);

        vm.stopBroadcast();

        // Post-deployment checks to ensure immutables match expected values
        // (guards against shell env variables overriding .env file)
        require(
            feeDisburser.L1_WALLET() == 0x23B597f33f6f2621F77DA117523Dffd634cDf4ea,
            "DeployFeeDisburser: L1_WALLET mismatch"
        );
        require(
            feeDisburser.FEE_DISBURSEMENT_INTERVAL() == 86400, "DeployFeeDisburser: FEE_DISBURSEMENT_INTERVAL mismatch"
        );
    }
}
