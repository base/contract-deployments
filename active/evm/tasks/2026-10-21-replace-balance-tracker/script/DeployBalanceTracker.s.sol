// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {BalanceTracker} from "@base-contracts/src/L1/BalanceTracker.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

/// @notice Deploys and initializes a new BalanceTracker proxy on L1, then hands its admin to NEW_ADMIN.
/// @dev The deployer is the proxy admin only until `changeAdmin` at the end of the same broadcast.
contract DeployBalanceTracker is Script {
    address payable internal immutable PROFIT_WALLET;
    address internal immutable NEW_ADMIN;
    address payable internal immutable SYSTEM_ADDRESS_0;
    uint256 internal immutable TARGET_BALANCE_0;
    address payable internal immutable SYSTEM_ADDRESS_1;
    uint256 internal immutable TARGET_BALANCE_1;

    // Deployment output written to addresses.json.
    address public balanceTrackerImpl;
    address payable public balanceTracker;

    constructor() {
        PROFIT_WALLET = payable(vm.envAddress("PROFIT_WALLET"));
        NEW_ADMIN = vm.envAddress("NEW_ADMIN");
        SYSTEM_ADDRESS_0 = payable(vm.envAddress("SYSTEM_ADDRESS_0"));
        TARGET_BALANCE_0 = vm.envUint("TARGET_BALANCE_0");
        SYSTEM_ADDRESS_1 = payable(vm.envAddress("SYSTEM_ADDRESS_1"));
        TARGET_BALANCE_1 = vm.envUint("TARGET_BALANCE_1");

        require(NEW_ADMIN.code.length > 0, "NEW_ADMIN has no code");
    }

    function run() external {
        address payable[] memory systemAddresses = new address payable[](2);
        systemAddresses[0] = SYSTEM_ADDRESS_0;
        systemAddresses[1] = SYSTEM_ADDRESS_1;
        uint256[] memory targetBalances = new uint256[](2);
        targetBalances[0] = TARGET_BALANCE_0;
        targetBalances[1] = TARGET_BALANCE_1;

        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();

        balanceTrackerImpl = address(new BalanceTracker(PROFIT_WALLET));
        Proxy proxy = new Proxy(deployer);
        proxy.upgradeToAndCall(
            balanceTrackerImpl, abi.encodeCall(BalanceTracker.initialize, (systemAddresses, targetBalances))
        );
        proxy.changeAdmin(NEW_ADMIN);

        vm.stopBroadcast();

        balanceTracker = payable(address(proxy));
        _postChecks(proxy);

        console.log("BalanceTracker implementation:", balanceTrackerImpl);
        console.log("BalanceTracker proxy:", balanceTracker);

        string memory path = vm.envString("ADDRESSES_JSON");
        vm.writeJson(vm.toString(balanceTrackerImpl), path, ".balanceTrackerImplementation");
        vm.writeJson(vm.toString(balanceTracker), path, ".balanceTracker");
    }

    function _postChecks(Proxy proxy) internal {
        vm.startPrank(address(0));
        require(proxy.admin() == NEW_ADMIN, "proxy admin mismatch");
        require(proxy.implementation() == balanceTrackerImpl, "implementation mismatch");
        vm.stopPrank();

        BalanceTracker tracker = BalanceTracker(balanceTracker);
        require(tracker.PROFIT_WALLET() == PROFIT_WALLET, "profit wallet mismatch");
        require(tracker.systemAddresses(0) == SYSTEM_ADDRESS_0, "system address 0 mismatch");
        require(tracker.systemAddresses(1) == SYSTEM_ADDRESS_1, "system address 1 mismatch");
        require(tracker.targetBalances(0) == TARGET_BALANCE_0, "target balance 0 mismatch");
        require(tracker.targetBalances(1) == TARGET_BALANCE_1, "target balance 1 mismatch");
        (bool hasThird,) = balanceTracker.staticcall(abi.encodeWithSelector(tracker.systemAddresses.selector, 2));
        require(!hasThird, "unexpected system address count");

        address payable[] memory none = new address payable[](0);
        (bool ok,) = balanceTracker.call(abi.encodeCall(BalanceTracker.initialize, (none, new uint256[](0))));
        require(!ok, "proxy can be reinitialized");
        (ok,) = balanceTrackerImpl.call(abi.encodeCall(BalanceTracker.initialize, (none, new uint256[](0))));
        require(!ok, "implementation can be initialized");

        uint256 snapshot = vm.snapshotState();
        uint256 profitBefore = PROFIT_WALLET.balance;
        vm.deal(balanceTracker, TARGET_BALANCE_0 + TARGET_BALANCE_1 + 1 ether);
        tracker.processFees();
        require(balanceTracker.balance == 0, "fees not processed");
        require(SYSTEM_ADDRESS_0.balance >= TARGET_BALANCE_0, "system address 0 not refilled");
        require(SYSTEM_ADDRESS_1.balance >= TARGET_BALANCE_1, "system address 1 not refilled");
        require(PROFIT_WALLET.balance >= profitBefore + 1 ether, "profit not sent");
        vm.revertToState(snapshot);
    }
}
