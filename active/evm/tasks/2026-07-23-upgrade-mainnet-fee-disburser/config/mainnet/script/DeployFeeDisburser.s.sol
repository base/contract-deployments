// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {FeeDisburser} from "@base-contracts/src/L2/FeeDisburser.sol";

contract DeployFeeDisburser is Script {
    address internal immutable BALANCE_TRACKER;
    uint256 internal immutable FEE_DISBURSEMENT_INTERVAL;

    constructor() {
        BALANCE_TRACKER = vm.envAddress("BALANCE_TRACKER");
        FEE_DISBURSEMENT_INTERVAL = vm.envUint("FEE_DISBURSEMENT_INTERVAL");
    }

    function run() external {
        vm.startBroadcast();
        FeeDisburser implementation = new FeeDisburser(BALANCE_TRACKER, FEE_DISBURSEMENT_INTERVAL);
        vm.stopBroadcast();

        require(implementation.L1_WALLET() == BALANCE_TRACKER, "L1 wallet mismatch");
        require(
            implementation.FEE_DISBURSEMENT_INTERVAL() == FEE_DISBURSEMENT_INTERVAL, "disbursement interval mismatch"
        );
        require(keccak256(bytes(implementation.version())) == keccak256(bytes("1.1.0")), "version mismatch");
        console.log("FeeDisburser implementation:", address(implementation));
    }
}
