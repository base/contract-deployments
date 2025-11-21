// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

contract InitOwnershipTransfer is MultisigScript {
    using AddressAliasHelper for address;

    address public immutable L1_OWNER_SAFE;
    address public immutable SMART_ESCROW;
    address public immutable OWNER_SAFE;

    constructor() {
        L1_OWNER_SAFE = vm.envAddress("L1_OWNER_SAFE");
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SMART_ESCROW = vm.envAddress("SMART_ESCROW");
    }

    // Confirm the proxy admin owner is now the pending admin of SmartEscrow
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        AccessControlDefaultAdminRules smartEscrow = AccessControlDefaultAdminRules(SMART_ESCROW);
        (address pendingAdmin,) = smartEscrow.pendingDefaultAdmin();
        require(pendingAdmin == L1_OWNER_SAFE.applyL1ToL2Alias(), "Pending admin is not L1_OWNER_SAFE");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: SMART_ESCROW,
            allowFailure: false,
            callData: abi.encodeCall(
                AccessControlDefaultAdminRules.beginDefaultAdminTransfer, (L1_OWNER_SAFE.applyL1ToL2Alias())
            ),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
