// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

contract TransferOwner is NestedMultisigBuilder {
    address internal _PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
    address internal _L2_PROXY_ADMIN_OWNER = vm.envAddress("L2_PROXY_ADMIN_OWNER");
    address internal _L1_PROXY_ADMIN_OWNER = vm.envAddress("L1_PROXY_ADMIN_OWNER");

    // Using example from OP L1 Proxy Admin to confirm accuracy of `_convertToAliasAddress`
    address internal constant _OP_L1_PROXY_ADMIN = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address internal constant _OP_L1_PROXY_ADMIN_ALIAS = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b;

    /// @dev Confirm the alias address conversion is correct using Optimism L1 Proxy Admin as an example
    constructor() {
        require(
            _convertToAliasAddress(_OP_L1_PROXY_ADMIN) == _OP_L1_PROXY_ADMIN_ALIAS,
            "Something wrong with ConvertToAlias"
        );
    }

    /// @dev Confirm the proxy admin owner is now the alias address of the L1 Proxy Admin Owner
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        OwnableUpgradeable proxyAdmin = OwnableUpgradeable(_PROXY_ADMIN);
        require(
            proxyAdmin.owner() == _convertToAliasAddress(_L1_PROXY_ADMIN_OWNER), "ProxyAdmin owner did not get updated"
        );
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: _PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(OwnableUpgradeable.transferOwnership, (_convertToAliasAddress(_L1_PROXY_ADMIN_OWNER)))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return _L2_PROXY_ADMIN_OWNER;
    }

    /// @dev An alias address is the original address + 0x1111000000000000000000000000000000001111
    function _convertToAliasAddress(address addr) private pure returns (address) {
        uint160 enumeratedAddress = uint160(addr);
        uint160 offset = uint160(0x1111000000000000000000000000000000001111);
        return address(enumeratedAddress + offset);
    }
}
