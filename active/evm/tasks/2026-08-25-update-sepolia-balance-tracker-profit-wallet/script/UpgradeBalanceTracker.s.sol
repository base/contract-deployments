// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {BalanceTracker} from "@base-contracts/src/L1/BalanceTracker.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

contract UpgradeBalanceTracker is Script {
    address internal immutable PROXY_ADMIN;
    address payable internal immutable BALANCE_TRACKER;
    address payable internal immutable CURRENT_PROFIT_WALLET;
    address payable internal immutable NEW_PROFIT_WALLET;
    address internal immutable NEW_IMPLEMENTATION;

    constructor() {
        BALANCE_TRACKER = payable(vm.envAddress("BALANCE_TRACKER"));

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        PROXY_ADMIN = vm.parseJsonAddress(json, ".proxyAdmin");
        CURRENT_PROFIT_WALLET = payable(vm.parseJsonAddress(json, ".currentProfitWallet"));
        NEW_PROFIT_WALLET = payable(vm.parseJsonAddress(json, ".newProfitWallet"));
        NEW_IMPLEMENTATION = vm.parseJsonAddress(json, ".balanceTrackerImplementation");

        require(NEW_IMPLEMENTATION.code.length > 0, "implementation has no code");
        require(
            BalanceTracker(payable(NEW_IMPLEMENTATION)).PROFIT_WALLET() == NEW_PROFIT_WALLET,
            "implementation profit wallet mismatch"
        );
        vm.prank(PROXY_ADMIN);
        require(Proxy(BALANCE_TRACKER).admin() == PROXY_ADMIN, "proxy admin mismatch");
        require(
            BalanceTracker(BALANCE_TRACKER).PROFIT_WALLET() == CURRENT_PROFIT_WALLET, "current profit wallet mismatch"
        );
    }

    function run() external {
        BalanceTracker balanceTracker = BalanceTracker(BALANCE_TRACKER);
        address systemAddress0 = balanceTracker.systemAddresses(0);
        address systemAddress1 = balanceTracker.systemAddresses(1);
        uint256 targetBalance0 = balanceTracker.targetBalances(0);
        uint256 targetBalance1 = balanceTracker.targetBalances(1);

        vm.broadcast(PROXY_ADMIN);
        Proxy(BALANCE_TRACKER).upgradeTo(NEW_IMPLEMENTATION);

        vm.prank(PROXY_ADMIN);
        require(Proxy(BALANCE_TRACKER).implementation() == NEW_IMPLEMENTATION, "implementation mismatch");
        require(balanceTracker.PROFIT_WALLET() == NEW_PROFIT_WALLET, "new profit wallet mismatch");
        require(balanceTracker.systemAddresses(0) == systemAddress0, "system address 0 changed");
        require(balanceTracker.systemAddresses(1) == systemAddress1, "system address 1 changed");
        require(balanceTracker.targetBalances(0) == targetBalance0, "target balance 0 changed");
        require(balanceTracker.targetBalances(1) == targetBalance1, "target balance 1 changed");
    }
}
