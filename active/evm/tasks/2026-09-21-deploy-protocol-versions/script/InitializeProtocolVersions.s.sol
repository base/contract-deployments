// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgradeAndCall(address payable proxy, address implementation, bytes memory data) external payable;
}

interface IProtocolVersions {
    function initialize(address incidentResponder, uint64[] calldata initialSchedule, uint256 minimumProtocolVersion)
        external;
    function getSchedule() external view returns (uint64[] memory);
    function incidentResponder() external view returns (address);
    function minimumProtocolVersion() external view returns (uint256);
    function proxyAdminOwner() external view returns (address);
    function scheduleId() external view returns (bytes32);
    function version() external view returns (string memory);
}

interface IVersioned {
    function version() external view returns (string memory);
}

/// @notice Initializes the new ProtocolVersions proxy through the ProxyAdmin owner Safe.
contract InitializeProtocolVersions is MultisigScript {
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable protocolVersionsProxy;
    address internal immutable protocolVersionsImpl;
    address internal immutable incidentResponder;
    uint256 internal immutable minimumProtocolVersion;

    uint64[] internal initialSchedule;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        protocolVersionsProxy = vm.envAddress("PROTOCOL_VERSIONS_PROXY");
        protocolVersionsImpl = vm.envAddress("PROTOCOL_VERSIONS_IMPL");
        incidentResponder = vm.envAddress("PROTOCOL_VERSIONS_INCIDENT_RESPONDER");
        minimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");

        uint256[] memory schedule = vm.envUint("PROTOCOL_VERSIONS_INITIAL_SCHEDULE", ",");
        for (uint256 i = 0; i < schedule.length; i++) {
            require(schedule[i] <= type(uint64).max, "schedule timestamp exceeds uint64");
            initialSchedule.push(uint64(schedule[i]));
        }
    }

    function setUp() public view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(protocolVersionsProxy),
                    protocolVersionsImpl,
                    abi.encodeCall(
                        IProtocolVersions.initialize, (incidentResponder, initialSchedule, minimumProtocolVersion)
                    )
                )
            ),
            value: 0
        });
        return calls;
    }

    function _preCheck() internal view {
        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");
        require(protocolVersionsProxy.code.length != 0, "protocol versions proxy not deployed");
        require(protocolVersionsImpl.code.length != 0, "protocol versions implementation not deployed");
        require(_slotAddress(protocolVersionsProxy, ADMIN_SLOT) == proxyAdmin, "protocol versions proxy admin mismatch");
        require(
            _slotAddress(protocolVersionsProxy, IMPLEMENTATION_SLOT) == address(0),
            "protocol versions proxy already initialized"
        );
        require(
            keccak256(bytes(IVersioned(protocolVersionsImpl).version())) == keccak256(bytes("1.0.0")),
            "protocol versions implementation version mismatch"
        );
        require(incidentResponder != address(0), "incident responder not set");
        require(initialSchedule.length != 0, "initial schedule not set");
        require(
            minimumProtocolVersion != 0 && minimumProtocolVersion <= type(uint128).max,
            "invalid minimum protocol version"
        );
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(
            _slotAddress(protocolVersionsProxy, IMPLEMENTATION_SLOT) == protocolVersionsImpl,
            "protocol versions implementation not updated"
        );

        IProtocolVersions registry = IProtocolVersions(protocolVersionsProxy);
        require(keccak256(bytes(registry.version())) == keccak256(bytes("1.0.0")), "registry version mismatch");
        require(registry.proxyAdminOwner() == ownerSafe, "registry owner mismatch");
        require(registry.incidentResponder() == incidentResponder, "registry responder mismatch");
        require(registry.minimumProtocolVersion() == minimumProtocolVersion, "registry minimum version mismatch");

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == initialSchedule.length, "registry schedule length mismatch");
        for (uint256 i = 0; i < schedule.length; i++) {
            require(schedule[i] == initialSchedule[i], "registry schedule entry mismatch");
        }
        require(registry.scheduleId() == _expectedScheduleId(), "registry schedule commitment mismatch");
    }

    function _expectedScheduleId() internal view returns (bytes32) {
        bytes32 link;
        for (uint256 i = 0; i < initialSchedule.length; i++) {
            link = keccak256(abi.encode(link, i, initialSchedule[i]));
        }
        return link;
    }

    function _slotAddress(address target, bytes32 slot) internal view returns (address) {
        return address(uint160(uint256(vm.load(target, slot))));
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
