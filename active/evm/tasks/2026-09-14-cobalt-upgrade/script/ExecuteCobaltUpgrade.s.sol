// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgrade(address payable proxy, address implementation) external;
    function upgradeAndCall(address payable proxy, address implementation, bytes memory data) external payable;
}

interface IProtocolVersions {
    function initialize(address incidentResponder, uint64[] calldata initialSchedule, uint256 minimumProtocolVersion)
        external;
    function getSchedule() external view returns (uint64[] memory);
    function incidentResponder() external view returns (address);
    function minimumProtocolVersion() external view returns (uint256);
    function scheduleId() external view returns (bytes32);
    function version() external view returns (string memory);
}

interface IDisputeGameFactory {
    function gameCount() external view returns (uint256);
    function gameImpls(uint32 gameType) external view returns (address);
    function owner() external view returns (address);
    function setImplementation(uint32 gameType, address impl) external;
    function version() external view returns (string memory);
}

interface IAggregateVerifier {
    function PROTOCOL_VERSIONS() external view returns (address);
    function version() external view returns (string memory);
}

interface ISystemConfig {
    function gasLimit() external view returns (uint64);
    function paused() external view returns (bool);
    function version() external view returns (string memory);
}

interface IVersioned {
    function version() external view returns (string memory);
}

/// @notice Executes the Cobalt L1 upgrade on a Base chain.
/// @dev Bundles the three Cobalt contract changes into a single ProxyAdmin-owner transaction:
///      dynamic upgrades (a new ProtocolVersions registry plus the AggregateVerifier that binds it),
///      the EthLockbox removal (OptimismPortal2 and SystemConfig), and CREATE2 dispute game proxies
///      (DisputeGameFactory).
contract ExecuteCobaltUpgrade is MultisigScript {
    /// @notice EIP-1967 implementation slot.
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Storage slot the removed `ethLockbox` address occupied on OptimismPortal2. The
    ///         Cobalt implementation replaces it with a spacer, so the stored value must survive
    ///         the upgrade untouched.
    bytes32 internal constant PORTAL_ETH_LOCKBOX_SLOT = bytes32(uint256(63));

    /// @notice Game type of the aggregate proof game.
    uint32 internal constant AGGREGATE_VERIFIER_GAME_TYPE = 621;

    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable optimismPortal;
    address internal immutable systemConfig;
    address internal immutable disputeGameFactory;

    address internal immutable oldOptimismPortalImpl;
    address internal immutable oldSystemConfigImpl;
    address internal immutable oldDisputeGameFactoryImpl;
    address internal immutable oldAggregateVerifier;

    address internal immutable newOptimismPortalImpl;
    address internal immutable newSystemConfigImpl;
    address internal immutable newDisputeGameFactoryImpl;
    address internal immutable newAggregateVerifier;
    address internal immutable protocolVersionsProxy;
    address internal immutable protocolVersionsImpl;

    address internal immutable protocolVersionsIncidentResponder;
    uint256 internal immutable protocolVersionsMinimumProtocolVersion;

    /// @dev Solidity has no immutable arrays, so the imported activation schedule is read from the
    ///      environment into storage during construction.
    uint64[] internal protocolVersionsInitialSchedule;

    /// @dev Live state captured at construction and re-asserted after the upgrade.
    uint256 internal immutable portalBalanceBefore;
    bytes32 internal immutable portalLockboxSlotBefore;
    uint64 internal immutable gasLimitBefore;
    uint256 internal immutable gameCountBefore;
    bool internal immutable pausedBefore;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        systemConfig = vm.envAddress("SYSTEM_CONFIG");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        oldOptimismPortalImpl = vm.envAddress("OLD_OPTIMISM_PORTAL_IMPL");
        oldSystemConfigImpl = vm.envAddress("OLD_SYSTEM_CONFIG_IMPL");
        oldDisputeGameFactoryImpl = vm.envAddress("OLD_DISPUTE_GAME_FACTORY_IMPL");
        oldAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");

        newOptimismPortalImpl = vm.envAddress("NEW_OPTIMISM_PORTAL_IMPL");
        newSystemConfigImpl = vm.envAddress("NEW_SYSTEM_CONFIG_IMPL");
        newDisputeGameFactoryImpl = vm.envAddress("NEW_DISPUTE_GAME_FACTORY_IMPL");
        newAggregateVerifier = vm.envAddress("NEW_AGGREGATE_VERIFIER");
        protocolVersionsProxy = vm.envAddress("PROTOCOL_VERSIONS_PROXY");
        protocolVersionsImpl = vm.envAddress("PROTOCOL_VERSIONS_IMPL");

        protocolVersionsIncidentResponder = vm.envAddress("PROTOCOL_VERSIONS_INCIDENT_RESPONDER");
        protocolVersionsMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");

        uint256[] memory schedule = vm.envUint("PROTOCOL_VERSIONS_INITIAL_SCHEDULE", ",");
        for (uint256 i = 0; i < schedule.length; i++) {
            require(schedule[i] <= type(uint64).max, "schedule timestamp exceeds uint64");
            protocolVersionsInitialSchedule.push(uint64(schedule[i]));
        }

        portalBalanceBefore = optimismPortal.balance;
        portalLockboxSlotBefore = vm.load(optimismPortal, PORTAL_ETH_LOCKBOX_SLOT);
        gasLimitBefore = ISystemConfig(systemConfig).gasLimit();
        gameCountBefore = IDisputeGameFactory(disputeGameFactory).gameCount();
        pausedBefore = ISystemConfig(systemConfig).paused();
    }

    function setUp() public view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](5);

        // Dynamic upgrades: point the new proxy at the registry implementation and seed the
        // activation schedule atomically. `initialize` is `reinitializer(1)` and the proxy has
        // never been initialized, so this must be `upgradeAndCall` rather than a bare upgrade.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(protocolVersionsProxy),
                    protocolVersionsImpl,
                    abi.encodeCall(
                        IProtocolVersions.initialize,
                        (
                            protocolVersionsIncidentResponder,
                            protocolVersionsInitialSchedule,
                            protocolVersionsMinimumProtocolVersion
                        )
                    )
                )
            ),
            value: 0
        });

        // EthLockbox removal. Both implementations are already at their current init version and
        // the upgrade adds no state, so they are upgrade-only.
        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(IProxyAdmin.upgrade, (payable(optimismPortal), newOptimismPortalImpl)),
            value: 0
        });
        calls[2] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(IProxyAdmin.upgrade, (payable(systemConfig), newSystemConfigImpl)),
            value: 0
        });

        // CREATE2 dispute game proxies.
        calls[3] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(IProxyAdmin.upgrade, (payable(disputeGameFactory), newDisputeGameFactoryImpl)),
            value: 0
        });

        // Register the AggregateVerifier that binds the new registry. This is `onlyOwner` on the
        // factory itself, not a ProxyAdmin call, and the factory owner is the same Safe.
        calls[4] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(
                IDisputeGameFactory.setImplementation, (AGGREGATE_VERIFIER_GAME_TYPE, newAggregateVerifier)
            ),
            value: 0
        });

        return calls;
    }

    function _preCheck() internal view {
        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");
        require(IDisputeGameFactory(disputeGameFactory).owner() == ownerSafe, "dispute game factory owner mismatch");

        require(_implementation(optimismPortal) == oldOptimismPortalImpl, "unexpected live portal implementation");
        require(_implementation(systemConfig) == oldSystemConfigImpl, "unexpected live system config implementation");
        require(
            _implementation(disputeGameFactory) == oldDisputeGameFactoryImpl,
            "unexpected live dispute game factory implementation"
        );
        require(
            IDisputeGameFactory(disputeGameFactory).gameImpls(AGGREGATE_VERIFIER_GAME_TYPE) == oldAggregateVerifier,
            "unexpected live aggregate verifier"
        );

        // The Cobalt portal drops every lockbox code path without migrating custody, so ETH held in
        // a live lockbox would be stranded. Zeronet never set one; this refuses to proceed anywhere
        // that did.
        (bool ok, bytes memory raw) = optimismPortal.staticcall(abi.encodeWithSignature("ethLockbox()"));
        require(!ok || abi.decode(raw, (address)) == address(0), "portal still uses an ETHLockbox");

        // The new registry must be an uninitialized proxy under the same ProxyAdmin.
        require(protocolVersionsProxy.code.length != 0, "protocol versions proxy not deployed");
        require(_implementation(protocolVersionsProxy) == address(0), "protocol versions proxy already upgraded");
        require(_admin(protocolVersionsProxy) == proxyAdmin, "protocol versions proxy admin mismatch");

        require(
            keccak256(bytes(IVersioned(protocolVersionsImpl).version())) == keccak256(bytes("1.0.0")),
            "protocol versions implementation version mismatch"
        );
        require(
            keccak256(bytes(IVersioned(newOptimismPortalImpl).version())) == keccak256(bytes("6.0.0")),
            "portal implementation version mismatch"
        );
        require(
            keccak256(bytes(IVersioned(newSystemConfigImpl).version()))
                == keccak256(bytes("3.14.0+max-gas-limit-2000M")),
            "system config implementation is not the patched build"
        );
        require(
            keccak256(bytes(IVersioned(newDisputeGameFactoryImpl).version())) == keccak256(bytes("1.5.0")),
            "dispute game factory implementation version mismatch"
        );
        require(
            keccak256(bytes(IAggregateVerifier(newAggregateVerifier).version())) == keccak256(bytes("0.2.0")),
            "aggregate verifier version mismatch"
        );
        require(newAggregateVerifier != oldAggregateVerifier, "aggregate verifier was not redeployed");
        require(
            IAggregateVerifier(newAggregateVerifier).PROTOCOL_VERSIONS() == protocolVersionsProxy,
            "aggregate verifier is not bound to the new registry"
        );

        require(protocolVersionsMinimumProtocolVersion != 0, "minimum protocol version not set");
        require(protocolVersionsMinimumProtocolVersion <= type(uint128).max, "minimum protocol version too large");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(_implementation(optimismPortal) == newOptimismPortalImpl, "portal implementation not updated");
        require(_implementation(systemConfig) == newSystemConfigImpl, "system config implementation not updated");
        require(
            _implementation(disputeGameFactory) == newDisputeGameFactoryImpl,
            "dispute game factory implementation not updated"
        );
        require(
            _implementation(protocolVersionsProxy) == protocolVersionsImpl,
            "protocol versions implementation not updated"
        );

        // Each changed contract bumps its semver, so reading version() back through the proxy
        // confirms it is serving the new code rather than just pointing at it.
        require(
            keccak256(bytes(IVersioned(optimismPortal).version())) == keccak256(bytes("6.0.0")),
            "portal not serving the new implementation"
        );
        require(
            keccak256(bytes(IDisputeGameFactory(disputeGameFactory).version())) == keccak256(bytes("1.5.0")),
            "dispute game factory not serving the new implementation"
        );

        // Dynamic upgrades: the registry is live and committed to the imported schedule.
        IProtocolVersions registry = IProtocolVersions(protocolVersionsProxy);
        require(keccak256(bytes(registry.version())) == keccak256(bytes("1.0.0")), "registry version mismatch");
        require(registry.incidentResponder() == protocolVersionsIncidentResponder, "registry responder mismatch");
        require(
            registry.minimumProtocolVersion() == protocolVersionsMinimumProtocolVersion,
            "registry minimum protocol version mismatch"
        );

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == protocolVersionsInitialSchedule.length, "registry schedule length mismatch");
        for (uint256 i = 0; i < schedule.length; i++) {
            require(schedule[i] == protocolVersionsInitialSchedule[i], "registry schedule entry mismatch");
        }
        require(registry.scheduleId() == _expectedScheduleId(), "registry schedule commitment mismatch");

        // CREATE2 dispute games: the factory keeps its full history and serves the new verifier.
        require(
            IDisputeGameFactory(disputeGameFactory).gameImpls(AGGREGATE_VERIFIER_GAME_TYPE) == newAggregateVerifier,
            "aggregate verifier not registered"
        );
        require(
            keccak256(bytes(IAggregateVerifier(newAggregateVerifier).version())) == keccak256(bytes("0.2.0")),
            "registered aggregate verifier is not the new build"
        );
        require(IDisputeGameFactory(disputeGameFactory).gameCount() == gameCountBefore, "game count changed");

        // EthLockbox removal must not move ETH, disturb the now-spacer slot, or change pause state.
        require(optimismPortal.balance == portalBalanceBefore, "portal balance changed");
        require(vm.load(optimismPortal, PORTAL_ETH_LOCKBOX_SLOT) == portalLockboxSlotBefore, "portal slot 63 changed");
        require(ISystemConfig(systemConfig).paused() == pausedBefore, "pause state changed");
        require(ISystemConfig(systemConfig).gasLimit() == gasLimitBefore, "gas limit changed");
        require(
            keccak256(bytes(ISystemConfig(systemConfig).version())) == keccak256(bytes("3.14.0+max-gas-limit-2000M")),
            "system config lost the max gas limit patch"
        );
    }

    /// @dev Recomputes the registry hash chain so the commitment is derived from the schedule this
    ///      script submitted rather than a pasted constant.
    function _expectedScheduleId() internal view returns (bytes32) {
        bytes32 link = bytes32(0);
        for (uint256 i = 0; i < protocolVersionsInitialSchedule.length; i++) {
            link = keccak256(abi.encode(link, i, protocolVersionsInitialSchedule[i]));
        }
        return link;
    }

    function _implementation(address proxy) internal view returns (address) {
        return address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
    }

    function _admin(address proxy) internal view returns (address) {
        // EIP-1967 admin slot.
        return
            address(
                uint160(uint256(vm.load(proxy, 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)))
            );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
