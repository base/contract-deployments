// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

contract TransferSystemConfigOwnership is MultisigScript {
    address internal immutable PROXY_ADMIN_OWNER;
    address internal immutable INCIDENT_MULTISIG;
    address internal immutable SYSTEM_CONFIG;

    constructor() {
        PROXY_ADMIN_OWNER = vm.envAddress("PROXY_ADMIN_OWNER");
        INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        require(IOwnable(SYSTEM_CONFIG).owner() == PROXY_ADMIN_OWNER, "current owner mismatch");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(IOwnable(SYSTEM_CONFIG).owner() == INCIDENT_MULTISIG, "new owner mismatch");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: SYSTEM_CONFIG,
            data: abi.encodeCall(IOwnable.transferOwnership, (INCIDENT_MULTISIG)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return PROXY_ADMIN_OWNER;
    }
}
