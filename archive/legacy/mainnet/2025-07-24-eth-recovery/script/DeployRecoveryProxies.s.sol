// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Recovery} from "@base-contracts/src/recovery/Recovery.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";

contract DeployRecoveryProxies is Script {
    using AddressAliasHelper for address;

    address internal ALIASED_INCIDENT_MULTISIG;
    address internal RECOVERY_IMPLEMENTATION;
    address[6] internal EXPECTED_PROXY_ADDRESSES;

    address[6] internal actualProxyAddresses;

    function setUp() public {
        ALIASED_INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG").applyL1ToL2Alias();
        RECOVERY_IMPLEMENTATION = vm.envAddress("RECOVERY_IMPLEMENTATION");

        string memory proxyAddressList = vm.envString("EXPECTED_PROXY_ADDRESSES");
        string[] memory addressStrings = vm.split(proxyAddressList, ",");
        require(addressStrings.length == 6, "Must provide exactly 6 proxy addresses");
        for (uint256 i; i < 6; i++) {
            EXPECTED_PROXY_ADDRESSES[i] = vm.parseAddress(addressStrings[i]);
        }
    }

    function run() public {
        vm.startBroadcast();
        for (uint256 i; i < EXPECTED_PROXY_ADDRESSES.length; i++) {
            address proxy = address(new ERC1967Proxy({_logic: RECOVERY_IMPLEMENTATION, _data: ""}));
            actualProxyAddresses[i] = proxy;
            console.log("Recovery proxy deployed at: ", proxy);
        }
        vm.stopBroadcast();

        _postCheck();
    }

    function _postCheck() internal {
        for (uint256 i; i < EXPECTED_PROXY_ADDRESSES.length; i++) {
            // Check that the proxies are deployed to the expected addresses
            require(actualProxyAddresses[i] == EXPECTED_PROXY_ADDRESSES[i], "Incorrect proxy address");

            // Check that the proxies owners are the expected addresses
            Recovery proxy = Recovery(actualProxyAddresses[i]);
            require(proxy.OWNER() == ALIASED_INCIDENT_MULTISIG, "Incorrect proxy owner");

            // Check that the proxies are upgradable
            vm.prank(ALIASED_INCIDENT_MULTISIG);
            UUPSUpgradeable(actualProxyAddresses[i]).upgradeTo(RECOVERY_IMPLEMENTATION);
        }
    }
}
