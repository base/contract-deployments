// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgrade(address payable proxy, address implementation) external;
}

interface IOptimismPortal {
    function anchorStateRegistry() external view returns (address);
    function guardian() external view returns (address);
    function l2Sender() external view returns (address);
    function paused() external view returns (bool);
    function proofMaturityDelaySeconds() external view returns (uint256);
    function systemConfig() external view returns (address);
    function version() external view returns (string memory);
}

/// @notice Upgrades OptimismPortal2 from 6.0.0 to 7.0.1.
/// @dev One `ProxyAdmin.upgrade` call from the ProxyAdmin owner Safe. Storage layout and init
///      version are unchanged, so there is nothing to reinitialize.
contract UpgradeOptimismPortal is MultisigScript {
    /// @notice EIP-1967 implementation slot.
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    string internal constant OLD_VERSION = "6.0.0";
    string internal constant NEW_VERSION = "7.0.1";

    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable optimismPortal;
    address internal immutable oldOptimismPortalImpl;
    address internal immutable newOptimismPortalImpl;

    /// @dev Live state captured at construction and re-asserted after the upgrade.
    uint256 internal immutable portalBalanceBefore;
    uint256 internal immutable proofMaturityDelaySecondsBefore;
    address internal immutable systemConfigBefore;
    address internal immutable anchorStateRegistryBefore;
    address internal immutable l2SenderBefore;
    address internal immutable guardianBefore;
    bool internal immutable pausedBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        oldOptimismPortalImpl = vm.envAddress("OLD_OPTIMISM_PORTAL_IMPL");
        newOptimismPortalImpl = vm.envAddress("NEW_OPTIMISM_PORTAL_IMPL");

        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");
        require(_implementation() == oldOptimismPortalImpl, "unexpected current portal implementation");
        require(_eq(IOptimismPortal(optimismPortal).version(), OLD_VERSION), "unexpected current portal version");

        require(newOptimismPortalImpl.code.length != 0, "new portal implementation not deployed");
        require(newOptimismPortalImpl != oldOptimismPortalImpl, "new portal implementation is the current one");
        require(_eq(IOptimismPortal(newOptimismPortalImpl).version(), NEW_VERSION), "new portal version mismatch");

        IOptimismPortal portal = IOptimismPortal(optimismPortal);
        proofMaturityDelaySecondsBefore = portal.proofMaturityDelaySeconds();
        require(
            IOptimismPortal(newOptimismPortalImpl).proofMaturityDelaySeconds() == proofMaturityDelaySecondsBefore,
            "new portal proof delay mismatch"
        );

        portalBalanceBefore = optimismPortal.balance;
        systemConfigBefore = portal.systemConfig();
        anchorStateRegistryBefore = portal.anchorStateRegistry();
        l2SenderBefore = portal.l2Sender();
        guardianBefore = portal.guardian();
        pausedBefore = portal.paused();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(IProxyAdmin.upgrade, (payable(optimismPortal), newOptimismPortalImpl)),
            value: 0
        });
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        IOptimismPortal portal = IOptimismPortal(optimismPortal);

        require(_implementation() == newOptimismPortalImpl, "portal implementation not upgraded");
        require(_eq(portal.version(), NEW_VERSION), "portal version not upgraded");

        require(optimismPortal.balance == portalBalanceBefore, "portal balance changed");
        require(portal.proofMaturityDelaySeconds() == proofMaturityDelaySecondsBefore, "proof delay changed");
        require(portal.systemConfig() == systemConfigBefore, "system config changed");
        require(portal.anchorStateRegistry() == anchorStateRegistryBefore, "anchor state registry changed");
        require(portal.l2Sender() == l2SenderBefore, "l2 sender changed");
        require(portal.guardian() == guardianBefore, "guardian changed");
        require(portal.paused() == pausedBefore, "pause state changed");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _implementation() internal view returns (address) {
        return address(uint160(uint256(vm.load(optimismPortal, IMPLEMENTATION_SLOT))));
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
