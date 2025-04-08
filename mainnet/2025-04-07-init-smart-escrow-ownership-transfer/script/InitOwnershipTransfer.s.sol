// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";

contract InitOwnershipTransfer is NestedMultisigBuilder {
    address public immutable OWNER_SAFE;
    address public immutable L1_SAFE;
    address public immutable TARGET;

    // Using example from OP L1 Proxy Admin to confirm accuracy of `_convertToAliasAddress`
    address public constant OP_L1_PROXY_ADMIN = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address public constant OP_L1_PROXY_ADMIN_ALIAS = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b;

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

    // Confirm the proxy admin owner is now the pending admin of SmartEscrow
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        AccessControlDefaultAdminRules target = AccessControlDefaultAdminRules(TARGET);
        (address pendingAdmin,) = target.pendingDefaultAdmin();
        require(pendingAdmin == _convertToAliasAddress(L1_SAFE), "Pending admin is not L1_SAFE");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: TARGET,
            allowFailure: false,
            callData: abi.encodeCall(
                AccessControlDefaultAdminRules.beginDefaultAdminTransfer, (_convertToAliasAddress(L1_SAFE))
            )
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
}
