// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract InitOwnershipTransfer is NestedMultisigBuilder {
    using AddressAliasHelper for address;

    address public immutable OWNER_SAFE;
    address public immutable L1_SAFE;
    address public immutable TARGET;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        L1_SAFE = vm.envAddress("L1_SAFE");
        TARGET = vm.envAddress("TARGET");
    }

    // Confirm the proxy admin owner is now the pending admin of SmartEscrow
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        AccessControlDefaultAdminRules target = AccessControlDefaultAdminRules(TARGET);
        (address pendingAdmin,) = target.pendingDefaultAdmin();
        require(pendingAdmin == L1_SAFE.applyL1ToL2Alias(), "Pending admin is not L1_SAFE");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: TARGET,
            allowFailure: false,
            callData: abi.encodeCall(AccessControlDefaultAdminRules.beginDefaultAdminTransfer, (L1_SAFE.applyL1ToL2Alias()))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
