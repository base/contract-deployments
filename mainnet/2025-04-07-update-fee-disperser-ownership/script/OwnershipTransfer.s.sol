// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract OwnershipTransfer is MultisigBuilder {
    address public immutable OWNER_SAFE;
    address public immutable L1_SAFE;
    address public immutable TARGET;

    // Using example from OP L1 Proxy Admin to confirm accuracy of `_convertToAliasAddress`
    address public constant OP_L1_PROXY_ADMIN = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address public constant OP_L1_PROXY_ADMIN_ALIAS = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b;

    bytes32 public constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        L1_SAFE = vm.envAddress("L1_SAFE");
        TARGET = vm.envAddress("TARGET");
    }

    // Confirm the alias address conversion is correct using Optimism L1 Proxy Admin as an example
    function setUp() public pure {
        require(
            _convertToAliasAddress(OP_L1_PROXY_ADMIN) == OP_L1_PROXY_ADMIN_ALIAS, "Something wrong with ConvertToAlias"
        );
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
                    storageAccess.newValue == _addressToBytes32(_convertToAliasAddress(L1_SAFE)),
                    "New value is not L1_SAFE"
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
            callData: abi.encodeCall(Proxy.changeAdmin, (_convertToAliasAddress(L1_SAFE)))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    /// @dev An alias address is the original address + 0x1111000000000000000000000000000000001111
    function _convertToAliasAddress(address addr) private pure returns (address) {
        uint160 enumeratedAddress = uint160(addr);
        uint160 offset = uint160(0x1111000000000000000000000000000000001111);
        return address(enumeratedAddress + offset);
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
