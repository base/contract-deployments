// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import {SequencerFeeVault, FeeVault} from "@eth-optimism-bedrock/src/L2/SequencerFeeVault.sol";
import {L1FeeVault} from "@eth-optimism-bedrock/src/L2/L1FeeVault.sol";
import {BaseFeeVault} from "@eth-optimism-bedrock/src/L2/BaseFeeVault.sol";

contract UpgradeFeeVaultProxy is Script {
    function run() public {
        ProxyAdmin proxyAdmin = ProxyAdmin(Predeploys.PROXY_ADMIN);
        address proxyAdminOwner = vm.envAddress("PROXY_ADMIN_OWNER");

        address payable sfvProxy = payable(Predeploys.SEQUENCER_FEE_WALLET);
        address payable lfvProxy = payable(Predeploys.L1_FEE_VAULT);
        address payable bfvProxy = payable(Predeploys.BASE_FEE_VAULT);

        address sfvNew = vm.envAddress("SEQUENCER_FEE_VAULT_IMPL");
        address lfvNew = vm.envAddress("L1_FEE_VAULT_IMPL");
        address bfvNew = vm.envAddress("BASE_FEE_VAULT_IMPL");

        vm.startBroadcast(proxyAdminOwner);
        proxyAdmin.upgrade(sfvProxy, address(sfvNew));
        require(
            proxyAdmin.getProxyImplementation(sfvProxy).codehash ==
                address(sfvNew).codehash,
            "SequencerFeeVault proxy not upgraded"
        );
        console.log("Upgraded Sequencer Fee Vault Impl.");
        proxyAdmin.upgrade(lfvProxy, address(lfvNew));
        require(
            proxyAdmin.getProxyImplementation(address(lfvProxy)).codehash ==
                address(lfvNew).codehash,
            "L1FeeVault proxy not Upgraded"
        );
        console.log("Upgraded L1 Fee Vault Impl.");
        proxyAdmin.upgrade(bfvProxy, address(bfvNew));
        require(
            proxyAdmin.getProxyImplementation(address(bfvProxy)).codehash ==
                address(bfvNew).codehash,
            "BaseFeeVault proxy not upgraded"
        );
        console.log("Upgraded Base Fee Vault Impl.");
        vm.stopBroadcast();
    }
}
