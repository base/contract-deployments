// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {L1Block} from "@base-contracts/src/L2/L1Block.sol";
import {L2ToL1MessagePasser} from "@base-contracts/src/L2/L2ToL1MessagePasser.sol";

/// @notice Deploys the L2ToL1MessagePasser and L1Block implementations on L2. The fee vaults are built with a
///         different compiler version and deployed by `DeployFeeVaultImpls`.
contract DeployL2PredeployImpls is Script {
    string internal constant L2_TO_L1_MESSAGE_PASSER_VERSION = "1.2.0";
    string internal constant L1_BLOCK_VERSION = "1.8.0";

    // Deployment output written to addresses.json.
    address public l2ToL1MessagePasser;
    address public l1Block;

    function run() external {
        vm.startBroadcast();

        l2ToL1MessagePasser = address(new L2ToL1MessagePasser());
        l1Block = address(new L1Block());

        vm.stopBroadcast();

        require(
            _eq(L2ToL1MessagePasser(payable(l2ToL1MessagePasser)).version(), L2_TO_L1_MESSAGE_PASSER_VERSION),
            "l2 to l1 message passer version mismatch"
        );
        require(_eq(L1Block(l1Block).version(), L1_BLOCK_VERSION), "l1 block version mismatch");

        console.log("L2ToL1MessagePasser:", l2ToL1MessagePasser);
        console.log("L1Block:", l1Block);

        string memory path = vm.envString("ADDRESSES_JSON");
        vm.writeJson(vm.toString(l2ToL1MessagePasser), path, ".l2ToL1MessagePasser");
        vm.writeJson(vm.toString(l1Block), path, ".l1Block");
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
