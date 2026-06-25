// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { console } from "forge-std/console.sol";
import { Script } from "forge-std/Script.sol";

import { Proxy } from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import { FeeDisburser } from "@base-contracts/src/revenue-share/FeeDisburser.sol";

contract DeployFeeDisburser is Script {
   function run() external {
        address deployer = vm.envAddress("FEE_DISBURSER_DEPLOYER");
        address payable optimismWallet = payable(vm.envAddress("OPTIMISM_WALLET"));
        address balanceTracker = vm.envAddress("BALANCE_TRACKER_PROXY");
        uint256 feeDisbursementInterval = vm.envUint("FEE_DISBURSEMENT_INTERVAL");
        address admin = vm.envAddress("FEE_DISBURSER_ADMIN");
        string memory salt = vm.envString("FEE_DISBURSER_SALT");

        console.log("Deployer: %s", deployer);
        console.log("Optimism Wallet: %s", optimismWallet);
        console.log("Balance Tracker: %s", balanceTracker);
        console.log("Fee Disbursement Interval: %s", feeDisbursementInterval);
        console.log("Admin: %s", admin);
        console.log("Salt: %s", salt);

        vm.broadcast(deployer);
        FeeDisburser feeDisburserImpl = new FeeDisburser(
            optimismWallet,
            balanceTracker,
            feeDisbursementInterval
        );
        require(feeDisburserImpl.OPTIMISM_WALLET() == optimismWallet, "DeployFeeDisburser: incorrect optimism wallet");
        require(feeDisburserImpl.L1_WALLET() == balanceTracker, "DeployFeeDisburser: incorrect l1 wallet");
        require(feeDisburserImpl.FEE_DISBURSEMENT_INTERVAL() == feeDisbursementInterval, "DeployFeeDisburser: incorrect fee disbursement interval");

        vm.broadcast(deployer);
        Proxy proxy = new Proxy{ salt: keccak256(abi.encode(salt))}(deployer);
        vm.prank(address(0));
        require(proxy.admin() == deployer, "DeployFeeDisburser: incorrect proxy admin");
        
        vm.broadcast(deployer);
        proxy.changeAdmin(admin);
        vm.prank(address(0));
        require(proxy.admin() == admin, "DeployFeeDisburser: incorrect proxy admin");

        console.log("Fee Disburser Impl address: %s", address(feeDisburserImpl));
        console.log("Fee Disburser Proxy address: %s", address(proxy));
   }
}