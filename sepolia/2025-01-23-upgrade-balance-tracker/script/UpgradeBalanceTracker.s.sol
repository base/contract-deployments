// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BalanceTracker} from "@base-contracts/src/revenue-share/BalanceTracker.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract UpgradeBalanceTracker is Script {
    Proxy proxy;
    BalanceTracker balanceTracker;

    bytes initializeCall;

    address deployer;
    address payable profitWallet;
    address payable outputProposer;
    address payable batchSender;
    uint256 outputProposerTargetBalance;
    uint256 batchSenderTargetBalance;

    function setUp() public {
        deployer = vm.envAddress("BALANCE_TRACKER_DEPLOYER");
        profitWallet = payable(vm.envAddress("PROFIT_WALLET"));
        outputProposer = payable(vm.envAddress("OUTPUT_PROPOSER"));
        batchSender = payable(vm.envAddress("BATCH_SENDER"));
        outputProposerTargetBalance = vm.envUint("OUTPUT_PROPOSER_TARGET_BALANCE");
        batchSenderTargetBalance = vm.envUint("BATCH_SENDER_TARGET_BALANCE");
        address payable proxyAddress = payable(vm.envAddress("BALANCE_TRACKER_PROXY"));

        console.log("Deployer: %s", deployer);
        console.log("Profit Wallet: %s", profitWallet);
        console.log("Output Proposer: %s", outputProposer);
        console.log("Batch Sender: %s", batchSender);
        console.log("Output Proposer Target Balance: %s", outputProposerTargetBalance);
        console.log("Batch Sender Target Balance: %s", batchSenderTargetBalance);
        console.log("Proxy Address: %s", proxyAddress);

        address payable[] memory systemAddresses = new address payable[](2);
        uint256[] memory targetBalances = new uint256[](2);

        systemAddresses[0] = outputProposer;
        systemAddresses[1] = batchSender;
        targetBalances[0] = outputProposerTargetBalance;
        targetBalances[1] = batchSenderTargetBalance;

        initializeCall = abi.encodeCall(BalanceTracker.initialize, (systemAddresses, targetBalances));

        proxy = Proxy(proxyAddress);
        balanceTracker = BalanceTracker(payable(address(proxy)));

        _preChecks();
    }

    function run() public {
        address balanceTrackerImpl = _deployImplementation();
        _upgradeProxy(balanceTrackerImpl);
        _postChecks(balanceTrackerImpl);

        console.log("Balance Tracker Impl address: %s", address(balanceTrackerImpl));
        console.log("Balance Tracker Proxy address: %s", address(proxy));
    }

    function _deployImplementation() private returns (address) {
        vm.broadcast(deployer);
        return address(new BalanceTracker(profitWallet));
    }

    function _upgradeProxy(address balanceTrackerImpl) private {
        vm.broadcast(deployer);
        proxy.upgradeToAndCall(balanceTrackerImpl, initializeCall);
    }

    function _preChecks() private view {
        require(balanceTracker.PROFIT_WALLET() == profitWallet, "Precheck: incorrect profit wallet");
        require(balanceTracker.systemAddresses(0) != outputProposer, "Precheck: incorrect output proposer");
        require(balanceTracker.systemAddresses(1) != batchSender, "Precheck: incorrect batch sender");
        require(
            balanceTracker.targetBalances(0) == outputProposerTargetBalance,
            "Precheck: incorrect output proposer target balance"
        );
        require(
            balanceTracker.targetBalances(1) == batchSenderTargetBalance,
            "Precheck: incorrect batch sender target balance"
        );
    }

    function _postChecks(address balanceTrackerImpl) private {
        vm.prank(address(0));
        require(proxy.implementation() == balanceTrackerImpl, "Postcheck: incorrect implementation");
        require(balanceTracker.PROFIT_WALLET() == profitWallet, "Postcheck: incorrect profit wallet");
        require(balanceTracker.systemAddresses(0) == outputProposer, "Postcheck: incorrect output proposer");
        require(balanceTracker.systemAddresses(1) == batchSender, "Postcheck: incorrect batch sender");
        require(
            balanceTracker.targetBalances(0) == outputProposerTargetBalance,
            "Postcheck: incorrect output proposer target balance"
        );
        require(
            balanceTracker.targetBalances(1) == batchSenderTargetBalance,
            "Postcheck: incorrect batch sender target balance"
        );
    }
}
