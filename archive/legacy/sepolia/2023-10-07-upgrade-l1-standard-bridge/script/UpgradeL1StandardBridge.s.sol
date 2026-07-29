// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/L1/L1StandardBridge.sol";
import "@eth-optimism-bedrock/contracts/L1/L1CrossDomainMessenger.sol";
import "forge-std/Script.sol";
import {ProxyAdmin} from "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";

contract UpgradeL1StandardBridge is Script {
    address internal L1_STANDARD_BRIDGE_PROXY = vm.envAddress("L1_STANDARD_BRIDGE_PROXY");
    address internal NEW_IMPLEMENTATION = 0xACd2E50B877ab12924a766b8dDBd9272402C7d72;
    address internal PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
    address internal PROXY_ADMIN_OWNER = vm.envAddress("PROXY_ADMIN_OWNER");

    function run() public {
        L1StandardBridge proxy = L1StandardBridge(payable(L1_STANDARD_BRIDGE_PROXY));

        CrossDomainMessenger messenger = proxy.messenger();
        console.log("Current L1CrossDomainMessenger value: %s", address(messenger));

        string memory version = proxy.version();
        console.log("Current L1StandardBridge version: %s", version);

        L1StandardBridge bridge = L1StandardBridge(payable(NEW_IMPLEMENTATION));
        console.log("Upgrading L1StandardBridge implementation to: %s", address(bridge));

        require(address(bridge.MESSENGER()) == address(0));
        require(address(bridge.messenger()) == address(0));
        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);

        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN);
        require(uint256(proxyAdmin.proxyType(L1_STANDARD_BRIDGE_PROXY)) == uint256(ProxyAdmin.ProxyType.CHUGSPLASH));

        vm.broadcast(PROXY_ADMIN_OWNER);
        proxyAdmin.upgradeAndCall({
            _proxy: payable(L1_STANDARD_BRIDGE_PROXY),
            _implementation: address(bridge),
            _data: abi.encodeCall(L1StandardBridge.initialize, (L1CrossDomainMessenger(address(messenger))))
        });

        version = proxy.version();
        console.log("New L1StandardBridge version: %s", version);
        console.log("New L1CrossDomainMessenger value: %s", address(proxy.messenger()));

        require(address(proxy.MESSENGER()) == address(messenger));
        require(address(proxy.messenger()) == address(messenger));
        require(address(proxy.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(proxy.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);
    }
}
