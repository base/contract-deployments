// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

contract TransferSystemConfigOwnership is MultisigScript {
    address internal immutable NEW_OWNER;
    address internal immutable SYSTEM_CONFIG;

    constructor() {
        NEW_OWNER = vm.envAddress("NEW_OWNER");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        OwnableUpgradeable systemConfig = OwnableUpgradeable(SYSTEM_CONFIG);
        vm.assertEq(systemConfig.owner(), NEW_OWNER, "SystemConfig owner did not get updated");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(OwnableUpgradeable.transferOwnership, (NEW_OWNER)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        OwnableUpgradeable systemConfig = OwnableUpgradeable(SYSTEM_CONFIG);
        return systemConfig.owner();
    }
}
