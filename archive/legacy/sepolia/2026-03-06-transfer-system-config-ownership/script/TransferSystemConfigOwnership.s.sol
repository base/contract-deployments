// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

contract TransferSystemConfigOwnership is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable NEW_OWNER;
    address internal immutable SYSTEM_CONFIG;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        NEW_OWNER = vm.envAddress("NEW_OWNER");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        OwnableUpgradeable systemConfig = OwnableUpgradeable(SYSTEM_CONFIG);
        vm.assertEq(systemConfig.owner(), NEW_OWNER, "SystemConfig owner did not get updated");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(OwnableUpgradeable.transferOwnership, (NEW_OWNER)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
