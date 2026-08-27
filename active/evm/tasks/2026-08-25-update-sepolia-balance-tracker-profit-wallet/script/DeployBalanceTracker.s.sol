// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {BalanceTracker} from "@base-contracts/src/L1/BalanceTracker.sol";

contract DeployBalanceTracker is Script {
    address payable internal immutable BALANCE_TRACKER;
    address internal immutable PROXY_ADMIN;
    address payable internal immutable CURRENT_PROFIT_WALLET;
    address payable internal immutable NEW_PROFIT_WALLET;

    constructor() {
        BALANCE_TRACKER = payable(vm.envAddress("BALANCE_TRACKER"));

        string memory json = vm.readFile(vm.envString("ADDRESSES_JSON"));
        PROXY_ADMIN = vm.parseJsonAddress(json, ".proxyAdmin");
        CURRENT_PROFIT_WALLET = payable(vm.parseJsonAddress(json, ".currentProfitWallet"));
        NEW_PROFIT_WALLET = payable(vm.parseJsonAddress(json, ".newProfitWallet"));

        require(
            BalanceTracker(BALANCE_TRACKER).PROFIT_WALLET() == CURRENT_PROFIT_WALLET, "current profit wallet mismatch"
        );
    }

    function run() external {
        vm.broadcast();
        BalanceTracker implementation = new BalanceTracker(NEW_PROFIT_WALLET);

        require(implementation.PROFIT_WALLET() == NEW_PROFIT_WALLET, "new profit wallet mismatch");

        string memory root = "addresses";
        vm.serializeAddress(root, "proxyAdmin", PROXY_ADMIN);
        vm.serializeAddress(root, "currentProfitWallet", CURRENT_PROFIT_WALLET);
        vm.serializeAddress(root, "newProfitWallet", NEW_PROFIT_WALLET);
        string memory json = vm.serializeAddress(root, "balanceTrackerImplementation", address(implementation));
        vm.writeJson(json, vm.envString("ADDRESSES_JSON"));
    }
}
