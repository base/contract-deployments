// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {OptimismMintableERC721Factory} from "@base-contracts/src/L2/OptimismMintableERC721Factory.sol";
import {OptimismMintableERC20Factory} from "@base-contracts/src/universal/OptimismMintableERC20Factory.sol";

contract DeployFactory is Script {
    address internal immutable bridge = vm.envAddress("FACTORY_BRIDGE");
    uint256 internal immutable remoteChainId = vm.envUint("REMOTE_CHAIN_ID");

    function run() external {
        vm.startBroadcast();
        OptimismMintableERC721Factory implementation = new OptimismMintableERC721Factory(bridge, remoteChainId);
        OptimismMintableERC20Factory erc20Implementation = new OptimismMintableERC20Factory();
        vm.stopBroadcast();
        require(keccak256(bytes(implementation.version())) == keccak256("1.4.2"), "factory version mismatch");
        require(
            keccak256(bytes(erc20Implementation.version())) == keccak256("1.10.2"), "ERC20 factory version mismatch"
        );
        vm.writeJson(
            vm.toString(address(erc20Implementation)), vm.envString("ADDRESSES_JSON"), ".optimismMintableERC20Factory"
        );
        vm.writeJson(
            vm.toString(address(implementation)), vm.envString("ADDRESSES_JSON"), ".optimismMintableERC721Factory"
        );
    }
}
