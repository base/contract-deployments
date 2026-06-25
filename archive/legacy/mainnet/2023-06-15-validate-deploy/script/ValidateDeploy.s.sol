// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@base-contracts/script/deploy/l1/CheckBedrockDeploy.s.sol";

contract ValidateDeploy is Script {
    function run() public {
        CheckBedrockDeploy checkBedrockDeploy = new CheckBedrockDeploy();
        checkBedrockDeploy.setup();
        checkBedrockDeploy.run();
    }
}
