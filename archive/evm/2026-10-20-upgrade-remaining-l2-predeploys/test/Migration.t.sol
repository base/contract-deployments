// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {L2UpgradeTest} from "./L2Upgrade.t.sol";
import {LegacyMigrator} from "../script/LegacyMigrator.sol";
import {IProxyAdmin} from "interfaces/universal/IProxyAdmin.sol";
import {AddressAliasHelper} from "src/vendor/AddressAliasHelper.sol";

contract MigrationTest is L2UpgradeTest {
    function testRevertingMigrationIsAtomic() public {
        address[8] memory implementations = _implementations();
        for (uint256 i = 4; i < 8; i++) {
            address proxy = _proxies()[i];
            address beforeImpl = IProxyAdmin(ADMIN).getProxyImplementation(proxy);
            bytes32 beforeSlot = vm.load(proxy, bytes32(0));
            vm.prank(AddressAliasHelper.applyL1ToL2Alias(ownerSafe));
            (bool ok,) = ADMIN.call(
                abi.encodeCall(
                    IProxyAdmin.upgradeAndCall,
                    (
                        payable(proxy),
                        localMigrator,
                        abi.encodeCall(LegacyMigrator.migrate, (implementations[i], hex"ffffffff"))
                    )
                )
            );
            require(!ok, "failed initializer did not revert migration");
            require(
                IProxyAdmin(ADMIN).getProxyImplementation(proxy) == beforeImpl,
                "failed migration changed implementation"
            );
            require(vm.load(proxy, bytes32(0)) == beforeSlot, "failed migration changed slot zero");
        }
    }

    function testDirectMigrationReverts() public {
        LegacyMigrator migrator = new LegacyMigrator();
        (bool ok,) = address(migrator).call(abi.encodeCall(LegacyMigrator.migrate, (address(1), bytes(""))));
        require(!ok, "direct migration did not revert");
    }
}
