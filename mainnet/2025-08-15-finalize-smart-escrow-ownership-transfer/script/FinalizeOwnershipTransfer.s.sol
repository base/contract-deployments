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
        PORTAL = vm.envAddress("PORTAL");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        address to = TARGET;
        uint256 value = 0;
        uint64 gasLimit = 2_000_000;
        bool isCreation = false;
        bytes memory data = abi.encodeCall(AccessControlDefaultAdminRules.acceptDefaultAdminTransfer);

        calls[0] = IMulticall3.Call3({
            target: PORTAL,
            allowFailure: false,
            callData: abi.encodeCall(IOptimismPortal2.depositTransaction, (to, value, gasLimit, isCreation, data)),
            value: value
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
