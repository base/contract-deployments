// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

import { BalanceTracker } from "@base-contracts/src/revenue-share/BalanceTracker.sol";

contract DeployBalanceTracker is Script {
   function run() external {
        address payable profitWallet = payable(vm.envAddress("PROFIT_WALLET"));

        console.log("Profit Wallet: %s", profitWallet);

        vm.broadcast();
        BalanceTracker balanceTrackerImpl = new BalanceTracker(profitWallet);
        require(balanceTrackerImpl.PROFIT_WALLET() == profitWallet, "DeployBalanceTracker: incorrect profit wallet");

        console.log("Balance Tracker Impl address: %s", address(balanceTrackerImpl));
   }
}
