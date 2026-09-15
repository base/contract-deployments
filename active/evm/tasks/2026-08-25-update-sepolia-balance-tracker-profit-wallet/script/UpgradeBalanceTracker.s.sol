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
    address payable internal immutable SYSTEM_ADDRESS_0;
    address payable internal immutable SYSTEM_ADDRESS_1;
    uint256 internal immutable TARGET_BALANCE_0;
    uint256 internal immutable TARGET_BALANCE_1;

    constructor() {
        PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
        BALANCE_TRACKER = payable(vm.envAddress("BALANCE_TRACKER"));
        CURRENT_PROFIT_WALLET = payable(vm.envAddress("CURRENT_PROFIT_WALLET"));
        NEW_PROFIT_WALLET = payable(vm.envAddress("NEW_PROFIT_WALLET"));
        SYSTEM_ADDRESS_0 = payable(vm.envAddress("SYSTEM_ADDRESS_0"));
        SYSTEM_ADDRESS_1 = payable(vm.envAddress("SYSTEM_ADDRESS_1"));
        TARGET_BALANCE_0 = vm.envUint("TARGET_BALANCE_0");
        TARGET_BALANCE_1 = vm.envUint("TARGET_BALANCE_1");

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        NEW_IMPLEMENTATION = vm.parseJsonAddress(json, ".balanceTrackerImplementation");

        require(NEW_IMPLEMENTATION.code.length > 0, "implementation has no code");
        require(
            BalanceTracker(payable(NEW_IMPLEMENTATION)).PROFIT_WALLET() == NEW_PROFIT_WALLET,
            "implementation profit wallet mismatch"
        );
        vm.prank(PROXY_ADMIN);
        require(Proxy(BALANCE_TRACKER).admin() == PROXY_ADMIN, "proxy admin mismatch");
        _checkState(CURRENT_PROFIT_WALLET);
    }

    function run() external {
        vm.broadcast(PROXY_ADMIN);
        Proxy(BALANCE_TRACKER).upgradeTo(NEW_IMPLEMENTATION);

        vm.prank(PROXY_ADMIN);
        require(Proxy(BALANCE_TRACKER).implementation() == NEW_IMPLEMENTATION, "implementation mismatch");
        _checkState(NEW_PROFIT_WALLET);
    }

    function _checkState(address expectedProfitWallet) internal view {
        BalanceTracker balanceTracker = BalanceTracker(BALANCE_TRACKER);

        require(balanceTracker.PROFIT_WALLET() == expectedProfitWallet, "profit wallet mismatch");
        require(balanceTracker.systemAddresses(0) == SYSTEM_ADDRESS_0, "system address 0 mismatch");
        require(balanceTracker.systemAddresses(1) == SYSTEM_ADDRESS_1, "system address 1 mismatch");
        require(balanceTracker.targetBalances(0) == TARGET_BALANCE_0, "target balance 0 mismatch");
        require(balanceTracker.targetBalances(1) == TARGET_BALANCE_1, "target balance 1 mismatch");
    }
}
