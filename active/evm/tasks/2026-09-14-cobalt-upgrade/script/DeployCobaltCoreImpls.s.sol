// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {DisputeGameFactory} from "@base-contracts/src/L1/proofs/DisputeGameFactory.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";

/// @notice Deploys the Cobalt implementations that base/contracts compiles at 5000 optimizer runs,
///         plus the proxy that will front the new ProtocolVersions registry.
/// @dev The ProtocolVersions proxy is deployed here, ahead of the implementations in
///      DeployCobaltProofImpls, because AggregateVerifier takes its address as a constructor
///      immutable. The proxy is left pointing at no implementation; the upgrade transaction
///      atomically sets the implementation and initializes it via ProxyAdmin.upgradeAndCall.
contract DeployCobaltCoreImpls is Script {
    address internal immutable l1ProxyAdmin;
    uint256 internal immutable proofMaturityDelaySeconds;
    string internal addressesJson;

    DisputeGameFactory public disputeGameFactoryImpl;
    OptimismPortal2 public optimismPortalImpl;
    Proxy public protocolVersionsProxy;
    SystemConfig public systemConfigImpl;

    constructor() {
        l1ProxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        proofMaturityDelaySeconds = vm.envUint("PROOF_MATURITY_DELAY_SECONDS");
        addressesJson = vm.envString("ADDRESSES_JSON");
    }

    function setUp() public view {
        require(l1ProxyAdmin.code.length != 0, "proxy admin not deployed");
    }

    function run() external {
        vm.startBroadcast();

        optimismPortalImpl = new OptimismPortal2(proofMaturityDelaySeconds);
        systemConfigImpl = new SystemConfig();
        disputeGameFactoryImpl = new DisputeGameFactory();
        protocolVersionsProxy = new Proxy(l1ProxyAdmin);

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(address(optimismPortalImpl).code.length != 0, "portal implementation not deployed");
        require(address(systemConfigImpl).code.length != 0, "system config implementation not deployed");
        require(address(disputeGameFactoryImpl).code.length != 0, "dispute game factory implementation not deployed");
        require(address(protocolVersionsProxy).code.length != 0, "protocol versions proxy not deployed");

        require(
            optimismPortalImpl.proofMaturityDelaySeconds() == proofMaturityDelaySeconds, "portal proof delay mismatch"
        );
        require(keccak256(bytes(optimismPortalImpl.version())) == keccak256(bytes("5.2.0")), "portal version mismatch");
        // Zeronet runs a patched SystemConfig that raises MAX_GAS_LIMIT to 2e9. The patch carries a
        // build-suffixed semver so a stock build cannot be deployed here by mistake.
        require(
            keccak256(bytes(systemConfigImpl.version())) == keccak256(bytes("3.13.2+max-gas-limit-2000M")),
            "system config patch not applied"
        );
        require(
            keccak256(bytes(disputeGameFactoryImpl.version())) == keccak256(bytes("1.4.0")),
            "dispute game factory version mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("OptimismPortal2 impl:    ", address(optimismPortalImpl));
        console.log("SystemConfig impl:       ", address(systemConfigImpl));
        console.log("DisputeGameFactory impl: ", address(disputeGameFactoryImpl));
        console.log("ProtocolVersions proxy:  ", address(protocolVersionsProxy));

        vm.writeJson(vm.toString(address(optimismPortalImpl)), addressesJson, ".optimismPortalImpl");
        vm.writeJson(vm.toString(address(systemConfigImpl)), addressesJson, ".systemConfigImpl");
        vm.writeJson(vm.toString(address(disputeGameFactoryImpl)), addressesJson, ".disputeGameFactoryImpl");
        vm.writeJson(vm.toString(address(protocolVersionsProxy)), addressesJson, ".protocolVersionsProxy");
    }
}
