// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

/// @notice Moves the BalanceTracker proxy admin from the current EOA to the Base Sepolia multisig.
contract TransferBalanceTrackerOwnership is Script {
    address internal immutable CURRENT_ADMIN;
    address internal immutable NEW_ADMIN;
    address payable internal immutable BALANCE_TRACKER;

    constructor() {
        CURRENT_ADMIN = vm.envAddress("CURRENT_ADMIN");
        NEW_ADMIN = vm.envAddress("NEW_ADMIN");
        BALANCE_TRACKER = payable(vm.envAddress("BALANCE_TRACKER"));

        require(NEW_ADMIN.code.length > 0, "NEW_ADMIN has no code");
        require(_admin() == CURRENT_ADMIN, "proxy admin is not CURRENT_ADMIN");
    }

    function run() external {
        vm.broadcast(CURRENT_ADMIN);
        Proxy(BALANCE_TRACKER).changeAdmin(NEW_ADMIN);

        require(_admin() == NEW_ADMIN, "proxy admin is not NEW_ADMIN");
    }

    function _admin() internal returns (address) {
        vm.prank(address(0));
        return Proxy(BALANCE_TRACKER).admin();
    }
}
