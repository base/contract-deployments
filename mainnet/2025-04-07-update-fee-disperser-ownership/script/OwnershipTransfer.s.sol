// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract OwnershipTransfer is MultisigBuilder {
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

    // Confirm the proxy admin owner is now the alias address of the L1 Proxy Admin Owner
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        Vm.AccountAccess memory targetAccess = _findAccountAccess(accesses, TARGET);

        bool seenTarget = false;

        for (uint256 i; i < targetAccess.storageAccesses.length; i++) {
            Vm.StorageAccess memory storageAccess = targetAccess.storageAccesses[i];
            if (storageAccess.slot == ADMIN_SLOT && storageAccess.isWrite) {
                require(!seenTarget, "Seen TARGET in storageAccesses");

                require(
                    storageAccess.previousValue == _addressToBytes32(OWNER_SAFE), "Previous value is not OWNER_SAFE"
                );
                require(
                    storageAccess.newValue == _addressToBytes32(L1_SAFE.applyL1ToL2Alias()), "New value is not L1_SAFE"
                );

                seenTarget = true;
            }
        }

        require(seenTarget, "Did not see TARGET in accesses");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: TARGET,
            allowFailure: false,
            callData: abi.encodeCall(Proxy.changeAdmin, (L1_SAFE.applyL1ToL2Alias()))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _findAccountAccess(Vm.AccountAccess[] memory accesses, address target)
        private
        pure
        returns (Vm.AccountAccess memory)
    {
        for (uint256 i; i < accesses.length; i++) {
            if (accesses[i].account == target) {
                return accesses[i];
            }
        }

        revert("Account access not found");
    }

    function _addressToBytes32(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
