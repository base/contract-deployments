// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {BalanceTracker} from "@base-contracts/src/L1/BalanceTracker.sol";

/// @title DeployBalanceTracker
/// @notice Deploys a fresh BalanceTracker implementation. The PROFIT_WALLET is `immutable` (baked
///         into the bytecode), so instead of trusting an env var it is read straight from the live
///         proxy — guaranteeing the new implementation keeps the exact profit wallet configured
///         onchain. The deployed address is written to addresses.json for UpgradeBalanceTracker.
contract DeployBalanceTracker is Script {
    // Config loaded from .env.
    address payable internal proxyEnv;

    function setUp() public {
        proxyEnv = payable(vm.envAddress("BALANCE_TRACKER"));
    }

    function run() external {
        // Source of truth: reuse the profit wallet already configured onchain.
        address payable profitWallet = BalanceTracker(proxyEnv).PROFIT_WALLET();
        require(profitWallet != address(0), "DeployBalanceTracker: profit wallet not set onchain");
        console.log("Profit Wallet (from onchain proxy):", profitWallet);

        vm.broadcast();
        BalanceTracker implementation = new BalanceTracker(profitWallet);

        require(implementation.PROFIT_WALLET() == profitWallet, "DeployBalanceTracker: incorrect profit wallet");
        console.log("BalanceTracker implementation deployed at:", address(implementation));

        // Persist for UpgradeBalanceTracker (addresses.json convention).
        string memory obj = "deployment";
        string memory json = vm.serializeAddress(obj, "balanceTrackerImplementation", address(implementation));
        vm.writeJson(json, "addresses.json");
    }
}
