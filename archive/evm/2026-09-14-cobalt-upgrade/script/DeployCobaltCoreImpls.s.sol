// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {DisputeGameFactory} from "@base-contracts/src/L1/proofs/DisputeGameFactory.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";

/// @notice Deploys the Cobalt implementations that base/contracts compiles at 5000 optimizer runs.
/// @dev Also deploys the ProtocolVersions proxy unless a previous task supplied one.
contract DeployCobaltCoreImpls is Script {
    address internal immutable l1ProxyAdmin;
    address internal immutable optimismPortal;
    address internal immutable existingProtocolVersionsProxy;
    bytes32 internal immutable expectedSystemConfigVersionHash;
    /// @dev Copied from the live portal so the redeploy cannot change the delay.
    uint256 internal immutable proofMaturityDelaySeconds;
    string internal addressesJson;

    DisputeGameFactory public disputeGameFactoryImpl;
    OptimismPortal2 public optimismPortalImpl;
    Proxy public protocolVersionsProxy;
    SystemConfig public systemConfigImpl;

    constructor() {
        l1ProxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        existingProtocolVersionsProxy = vm.envOr("EXISTING_PROTOCOL_VERSIONS_PROXY", address(0));
        expectedSystemConfigVersionHash = keccak256(bytes(vm.envString("EXPECTED_SYSTEM_CONFIG_VERSION")));
        proofMaturityDelaySeconds = OptimismPortal2(payable(optimismPortal)).proofMaturityDelaySeconds();
        addressesJson = vm.envString("ADDRESSES_JSON");
    }

    function setUp() public view {
        require(l1ProxyAdmin.code.length != 0, "proxy admin not deployed");
        require(optimismPortal.code.length != 0, "optimism portal not deployed");
    }

    function run() external {
        vm.startBroadcast();

        optimismPortalImpl = new OptimismPortal2(proofMaturityDelaySeconds);
        systemConfigImpl = new SystemConfig();
        disputeGameFactoryImpl = new DisputeGameFactory();
        protocolVersionsProxy = existingProtocolVersionsProxy == address(0)
            ? new Proxy(l1ProxyAdmin)
            : Proxy(payable(existingProtocolVersionsProxy));

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
        require(keccak256(bytes(optimismPortalImpl.version())) == keccak256(bytes("6.0.0")), "portal version mismatch");
        require(
            keccak256(bytes(systemConfigImpl.version())) == expectedSystemConfigVersionHash,
            "system config version mismatch"
        );
        require(
            keccak256(bytes(disputeGameFactoryImpl.version())) == keccak256(bytes("1.5.0")),
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

        // Recorded so `make verify-core` does not have to rebuild the encoding from
        // values the script resolved itself.
        vm.writeJson(
            vm.toString(abi.encode(proofMaturityDelaySeconds)), addressesJson, ".optimismPortalImplConstructorArgs"
        );
        if (existingProtocolVersionsProxy == address(0)) {
            vm.writeJson(vm.toString(abi.encode(l1ProxyAdmin)), addressesJson, ".protocolVersionsProxyConstructorArgs");
        }
    }
}
