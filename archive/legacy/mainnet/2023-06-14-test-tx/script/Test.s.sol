// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "src/Test.sol";

contract TestScript is Script {
    function run() public {
        vm.broadcast(0x0996bb0F5d56BB72c85C50Bd92A950E9756dF117);
        Test test = new Test();
        vm.broadcast(0x0996bb0F5d56BB72c85C50Bd92A950E9756dF117);
        test.increment();
    }
}
