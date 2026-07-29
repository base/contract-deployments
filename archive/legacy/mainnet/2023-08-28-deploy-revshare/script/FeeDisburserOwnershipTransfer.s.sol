// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";

contract FeeDisburserOwnershipTransfer is Script {
    address internal _proxyContract = vm.envAddress("FEE_DISBURSER_PROXY");
    address internal _oldOwner = vm.envAddress("FEE_DISBURSER_EXISTING_OWNER");
    address internal _newOwner = vm.envAddress("CB_SAFE_ADDR");

    function run() public {
        Proxy feeDisburserProxyContract = Proxy(payable(_proxyContract));

        vm.broadcast(_oldOwner);
        feeDisburserProxyContract.changeAdmin(_newOwner);

        vm.prank(address(0));
        require(
            feeDisburserProxyContract.admin() == _newOwner,
            "FeeDisburserOwnershipTransfer: Proxy owner did not get updated"
        );
    }
}
