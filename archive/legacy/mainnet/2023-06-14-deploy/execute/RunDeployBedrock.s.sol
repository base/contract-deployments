
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "@base-contracts/script/deploy/l1/DeployBedrock.s.sol";

contract RunDeployBedrock is Script {
    function run() public {
        DeployBedrock deployBedrock = new DeployBedrock();
        deployBedrock.run();
    }
}