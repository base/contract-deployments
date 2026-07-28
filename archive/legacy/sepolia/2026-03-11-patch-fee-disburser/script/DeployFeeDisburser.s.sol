// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {FeeDisburser} from "@base-contracts/src/revenue-share/FeeDisburser.sol";

/// @title DeployFeeDisburser
/// @notice Deploys the FeeDisburser implementation contract which collects fees from L2 FeeVaults
///         and bridges them to L1.
/// @dev Required environment variables:
///      - BALANCE_TRACKER: The L1 address that will receive bridged fees
///      - FEE_DISBURSEMENT_INTERVAL: Minimum time in seconds between disbursements (must be >= 24 hours)
///      - FEE_DISBURSER_ADDR: The existing FeeDisburser proxy contract on L2
contract DeployFeeDisburser is Script {
    address public immutable L1_WALLET = vm.envAddress("BALANCE_TRACKER");
    uint256 public immutable FEE_DISBURSEMENT_INTERVAL = vm.envUint("FEE_DISBURSEMENT_INTERVAL");
    address public immutable FEE_DISBURSER_PROXY = vm.envAddress("FEE_DISBURSER_ADDR");

    /// @notice EIP-1967 implementation storage slot.
    bytes32 internal constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function run() external {
        vm.startBroadcast();

        FeeDisburser feeDisburser = new FeeDisburser(L1_WALLET, FEE_DISBURSEMENT_INTERVAL);

        console.log("FeeDisburser deployed at:", address(feeDisburser));
        console.log("  L1_WALLET:", L1_WALLET);
        console.log("  FEE_DISBURSEMENT_INTERVAL:", FEE_DISBURSEMENT_INTERVAL);

        vm.stopBroadcast();

        require(feeDisburser.L1_WALLET() == L1_WALLET, "DeployFeeDisburser: L1_WALLET mismatch");
        require(
            feeDisburser.FEE_DISBURSEMENT_INTERVAL() == FEE_DISBURSEMENT_INTERVAL,
            "DeployFeeDisburser: FEE_DISBURSEMENT_INTERVAL mismatch"
        );

        _postCheck(address(feeDisburser));
    }

    /// @notice Simulates disburseFees() on the proxy with the newly deployed implementation
    ///         to verify ABI compatibility with the deployed FeeVaults.
    function _postCheck(address newImpl) internal {
        vm.store(FEE_DISBURSER_PROXY, IMPL_SLOT, bytes32(uint256(uint160(newImpl))));
        FeeDisburser(payable(FEE_DISBURSER_PROXY)).disburseFees();
        console.log("Postcheck: disburseFees() simulation succeeded with new implementation");
    }
}
