// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@eth-optimism-bedrock/src/dispute/AnchorStateRegistry.sol";
import "@eth-optimism-bedrock/src/dispute/weth/DelayedWETH.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";

contract VerifyContractState is Script {

    function run() public {
        verifyAnchorStateRegistry();
        verifyDelayedWETH();
        verifyDisputeGameFactory();
        verifyFaultDisputeGame();
        verifyPermissionedDisputeGame();
    }

    function verifyAnchorStateRegistry() internal view {
        address addr = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");

        address impl = bytes32ToAddress(vm.load(addr, Constants.PROXY_IMPLEMENTATION_ADDRESS));

        AnchorStateRegistry anchorStateRegistry = AnchorStateRegistry(addr);

        string memory version = anchorStateRegistry.version();
        address disputeGameFactoryAddr = address(anchorStateRegistry.disputeGameFactory());

        // Note that Hash is a custom type around bytes32
        (Hash rootCannon, uint256 l2BlockNumberCannon) = anchorStateRegistry.anchors(GameType.wrap(0));
        (Hash rootPermissionedCannon, uint256 l2BlockNumberPermissionedCannon) = anchorStateRegistry.anchors(GameType.wrap(1));

        console.log("AnchorStateRegistry: %s", addr);
        console.log("- Implementation address: %s", impl);
        console.log("- Version: %s", version);
        console.log("- DisputeGameFactory address: %s", disputeGameFactoryAddr);
        console.log("- Anchor for GameType.CANNON: %s, %s", vm.toString(Hash.unwrap(rootCannon)), l2BlockNumberCannon);
        console.log("- Anchor for GameType.PERMISSIONED_CANNON: %s, %s", vm.toString(Hash.unwrap(rootPermissionedCannon)), l2BlockNumberPermissionedCannon);
        console.log("==================\n");
    }

    function verifyDelayedWETH() internal {
        address addr = vm.envAddress("DELAYED_WETH_PROXY");

        address impl = bytes32ToAddress(vm.load(addr, Constants.PROXY_IMPLEMENTATION_ADDRESS));

        DelayedWETH delayedWeth = DelayedWETH(payable(addr));

        string memory version = delayedWeth.version();
        address owner = delayedWeth.owner();
        address config = address(delayedWeth.config());

        console.log("DelayedWETH: %s", addr);
        console.log("- Implementation address: %s", impl);
        console.log("- Version: %s", version);
        console.log("- Owner: %s", owner);
        console.log("- SuperchainConfig address: %s", config);
        console.log("==================\n");
    }

    function verifyDisputeGameFactory() internal {
        // TODO: Implement
    }

    function verifyFaultDisputeGame() internal {
        // TODO: Implement
    }

    function verifyPermissionedDisputeGame() internal {
        // TODO: Implement
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
