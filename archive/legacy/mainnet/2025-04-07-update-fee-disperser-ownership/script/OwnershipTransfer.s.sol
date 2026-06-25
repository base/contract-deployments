// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract OwnershipTransfer is MultisigScript {
    using AddressAliasHelper for address;

    address public immutable OWNER_SAFE;
    address public immutable L1_SAFE;
    address public immutable TARGET;

    bytes32 public constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        L1_SAFE = vm.envAddress("L1_SAFE");
        TARGET = vm.envAddress("TARGET");
    }

    // Confirm the aliased L1 proxy admin owner is now the owner of the fee dispurser
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        address expectedAdmin = L1_SAFE.applyL1ToL2Alias();

        vm.prank(expectedAdmin);
        address admin = Proxy(payable(TARGET)).admin();

        require(admin == expectedAdmin, "Admin is not L1_SAFE");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: TARGET,
            allowFailure: false,
            callData: abi.encodeCall(Proxy.changeAdmin, (L1_SAFE.applyL1ToL2Alias())),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
