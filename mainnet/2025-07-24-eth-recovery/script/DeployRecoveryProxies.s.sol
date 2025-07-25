// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {Recovery} from "../src/Recovery.sol";

contract DeployRecoveryProxies is Script {
    address internal INCIDENT_MULTISIG = vm.envAddress("INCIDENT_MULTISIG");

    address internal recoveryImplementation;

    address[6] internal expectedProxyAddresses = [
        0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E,
        0x8EfB6B5c4767B09Dc9AA6Af4eAA89F749522BaE2,
        0x3154Cf16ccdb4C6d922629664174b904d80F2C35,
        0x56315b90c40730925ec5485cf004d835058518A0,
        0x866E82a600A1414e583f7F13623F1aC5d58b0Afa,
        0x49048044D57e1C92A77f79988d21Fa8fAF74E97e
    ];

    address[6] internal actualProxyAddresses;

    function setUp() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        recoveryImplementation = vm.parseJsonAddress(json, ".implementation");
    }

    function run() public {
        vm.startBroadcast();
        for (uint256 i; i < expectedProxyAddresses.length; i++) {
            address proxy = address(new ERC1967Proxy({_logic: recoveryImplementation, _data: ""}));
            actualProxyAddresses[i] = proxy;
            console.log("Recovery proxy deployed at: ", proxy);
        }
        vm.stopBroadcast();

        _postCheck();
    }

    function _postCheck() internal {
        // Check that the proxies are deployed to the expected addresses
        for (uint256 i; i < expectedProxyAddresses.length; i++) {
            require(actualProxyAddresses[i] == expectedProxyAddresses[i], "Incorrect proxy address");
        }

        // Check that the proxies owners are the expected addresses
        for (uint256 i; i < expectedProxyAddresses.length; i++) {
            Recovery proxy = Recovery(actualProxyAddresses[i]);
            require(proxy.OWNER() == INCIDENT_MULTISIG, "Incorrect proxy owner");
        }

        // Check that the proxies are upgradable
        for (uint256 i; i < expectedProxyAddresses.length; i++) {
            vm.prank(INCIDENT_MULTISIG);
            UUPSUpgradeable(actualProxyAddresses[i]).upgradeTo(recoveryImplementation);
        }
    }
}
