// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {ProxyAdmin} from "@base-contracts/src/universal/ProxyAdmin.sol";
import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";
import {SuperchainConfig} from "@base-contracts/src/L1/SuperchainConfig.sol";

/// @title DeploySuperchainConfigAndSystemConfig
/// @notice Deploys a new SuperchainConfig proxy and a patched SystemConfig implementation.
///         The SuperchainConfig proxy is initialized with the guardian address and admin
///         is transferred to the ProxyAdmin contract. The SystemConfig implementation uses
///         init version 4 to allow re-initialization on existing proxies.
contract DeploySuperchainConfigAndSystemConfig is Script {
    /// @notice The ProxyAdmin contract that will be the admin of the SuperchainConfig proxy.
    address public immutable PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");

    /// @notice The Safe that owns the ProxyAdmin.
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");

    /// @notice The guardian address that can pause and perform dispute game operations (should be the same as the owner safe which is our top level 2-of-2).
    address public immutable GUARDIAN = vm.envAddress("OWNER_SAFE");

    /// @notice The incident responder address that can only pause.
    address public immutable INCIDENT_RESPONDER = vm.envAddress("CB_SIGNER_SAFE_ADDR");

    function run() external {
        vm.startBroadcast();

        // Deploy SuperchainConfig implementation with guardian and incident responder as constructor args
        SuperchainConfig superchainConfigImpl = new SuperchainConfig(GUARDIAN, INCIDENT_RESPONDER);

        // Deploy SuperchainConfig proxy
        Proxy superchainConfigProxy = new Proxy(msg.sender);
        superchainConfigProxy.upgradeTo(address(superchainConfigImpl));
        superchainConfigProxy.changeAdmin(PROXY_ADMIN);

        // Deploy patched SystemConfig implementation (uses init version 4)
        new SystemConfig();

        vm.stopBroadcast();

        // Post-deployment verification
        SuperchainConfig superchainConfig = SuperchainConfig(address(superchainConfigProxy));
        require(superchainConfig.GUARDIAN() == GUARDIAN, "Postcheck: Guardian not set correctly");
        require(
            superchainConfig.INCIDENT_RESPONDER() == INCIDENT_RESPONDER,
            "Postcheck: Incident responder not set correctly"
        );
        require(!superchainConfig.paused(), "Postcheck: SuperchainConfig should not be paused");

        // Verify proxy admin is set correctly
        vm.prank(address(0));
        require(superchainConfigProxy.admin() == PROXY_ADMIN, "Postcheck: Proxy admin not set correctly");

        // Verify proxy admin owner is correct
        require(ProxyAdmin(PROXY_ADMIN).owner() == OWNER_SAFE, "Postcheck: ProxyAdmin owner not set correctly");
    }
}
