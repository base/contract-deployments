
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";

contract RunERC20FactoryDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new OptimismMintableERC20Factory{salt: '0xBA5ED'}();
    }
}