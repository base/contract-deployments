// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

contract BasicScript is MultisigScript {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal TARGET = vm.envAddress("TARGET");

    function setUp() external {
        // TODO: Add any pre-check assertions here
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        // TODO: Add any post-check assertions here
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        // TODO: Add calls here
        calls[0] =
            Call({operation: Enum.Operation.Call, target: TARGET, data: "", value: 0});

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
