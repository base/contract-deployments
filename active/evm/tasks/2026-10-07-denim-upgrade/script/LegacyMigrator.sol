// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract LegacyMigrator {
    address private immutable self = address(this);

    event Upgraded(address indexed implementation);

    function migrate(address newImpl, bytes calldata initData) external {
        require(address(this) != self, "delegatecall only");
        // Legacy slot zero contains only initializer flags and obsolete configuration spacers.
        assembly {
            sstore(0, 0)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, newImpl)
        }
        emit Upgraded(newImpl);
        (bool ok, bytes memory reason) = newImpl.delegatecall(initData);
        if (!ok) assembly { revert(add(reason, 32), mload(reason)) }
    }
}
