// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";
import { BalanceTracker } from "@base-contracts/src/revenue-share/BalanceTracker.sol";

contract DeployBalanceTracker is Script {
   address payable[] systemAddresses;
   uint256[] targetBalances;

   function run() external {
        address deployer = vm.envAddress("BALANCE_TRACKER_DEPLOYER");
        address payable profitWallet = payable(vm.envAddress("PROFIT_WALLET"));
        address payable outputProposer = payable(vm.envAddress("OUTPUT_PROPOSER"));
        address payable batchSender = payable(vm.envAddress("BATCH_SENDER"));
        uint256 outputProposerTargetBalance = vm.envUint("OUTPUT_PROPOSER_TARGET_BALANCE");
        uint256 batchSenderTargetBalance = vm.envUint("BATCH_SENDER_TARGET_BALANCE");
        address admin = vm.envAddress("BALANCE_TRACKER_ADMIN");
        string memory salt = vm.envString("BALANCE_TRACKER_SALT");

        console.log("Deployer: %s", deployer);
        console.log("Profit Wallet: %s", profitWallet);
        console.log("Batch Sender: %s", batchSender);
        console.log("Output Proposer: %s", outputProposer);
        console.log("Batch Sender Target Balance: %s", batchSenderTargetBalance);
        console.log("Output Proposer Target Balance: %s", outputProposerTargetBalance);
        console.log("Admin: %s", admin);
        console.log("Salt: %s", salt);

        vm.broadcast(deployer);
        BalanceTracker balanceTrackerImpl = new BalanceTracker(profitWallet);
        require(balanceTrackerImpl.PROFIT_WALLET() == profitWallet, "DeployBalanceTracker: incorrect profit wallet");

        systemAddresses.push(outputProposer);
        systemAddresses.push(batchSender);
        targetBalances.push(outputProposerTargetBalance);
        targetBalances.push(batchSenderTargetBalance);

        bytes memory initializeCall = abi.encodeCall(
            BalanceTracker.initialize, (
            systemAddresses,
            targetBalances
            )
        );

        vm.broadcast(deployer);
        Proxy proxy = new Proxy{ salt: keccak256(abi.encode(salt))}(deployer);
        vm.prank(address(0));
        require(proxy.admin() == deployer, "DeployBalanceTracker: incorrect proxy admin");
        vm.broadcast(deployer);
        proxy.upgradeToAndCall(payable(address(balanceTrackerImpl)), initializeCall);
        BalanceTracker balanceTracker = BalanceTracker(payable(address(proxy)));
        require(balanceTracker.systemAddresses(0) == outputProposer, "DeployBalanceTracker: incorrect output proposer");
        require(balanceTracker.systemAddresses(1) == batchSender, "DeployBalanceTracker: incorrect batch sender");
        require(balanceTracker.targetBalances(0) == outputProposerTargetBalance, "DeployBalanceTracker: incorrect output proposer target balance");
        require(balanceTracker.targetBalances(1) == batchSenderTargetBalance, "DeployBalanceTracker: incorrect batch sender target balance");

        vm.broadcast(deployer);
        proxy.changeAdmin(admin);
        vm.prank(address(0));
        require(proxy.admin() == admin, "DeployBalanceTracker: incorrect proxy admin");

        console.log("Balance Tracker Impl address: %s", address(balanceTrackerImpl));
        console.log("Balance Tracker Proxy address: %s", address(proxy));
   }
}