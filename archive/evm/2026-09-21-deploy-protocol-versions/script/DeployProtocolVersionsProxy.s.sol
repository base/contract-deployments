// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IProtocolVersions} from "interfaces/L1/IProtocolVersions.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

/// @notice Deploys and initializes the ProtocolVersions proxy, then transfers it to the L1 ProxyAdmin.
contract DeployProtocolVersionsProxy is Script {
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address internal immutable deployer;
    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable protocolVersionsImpl;
    address internal immutable incidentResponder;
    uint256 internal immutable minimumProtocolVersion;
    string internal addressesJson;
    uint64[] internal initialSchedule;

    Proxy public protocolVersionsProxy;

    constructor() {
        deployer = vm.envAddress("DEPLOYER");
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        incidentResponder = vm.envAddress("PROTOCOL_VERSIONS_INCIDENT_RESPONDER");
        minimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");
        addressesJson = vm.envString("ADDRESSES_JSON");
        protocolVersionsImpl = vm.parseJsonAddress(vm.readFile(addressesJson), ".protocolVersionsImpl");

        uint256[] memory schedule = vm.envUint("PROTOCOL_VERSIONS_INITIAL_SCHEDULE", ",");
        for (uint256 i = 0; i < schedule.length; i++) {
            require(schedule[i] <= type(uint64).max, "schedule timestamp exceeds uint64");
            initialSchedule.push(uint64(schedule[i]));
        }
    }

    function setUp() public view {
        require(deployer != address(0), "deployer not set");
        require(proxyAdmin.code.length != 0, "proxy admin not deployed");
        require(protocolVersionsImpl.code.length != 0, "protocol versions implementation not deployed");
        require(incidentResponder != address(0), "incident responder not set");
        require(initialSchedule.length != 0, "initial schedule not set");
        require(
            minimumProtocolVersion != 0 && minimumProtocolVersion <= type(uint128).max,
            "invalid minimum protocol version"
        );
    }

    function run() external {
        vm.startBroadcast();

        protocolVersionsProxy = new Proxy(deployer);
        protocolVersionsProxy.upgradeToAndCall(
            protocolVersionsImpl,
            abi.encodeCall(IProtocolVersions.initialize, (incidentResponder, initialSchedule, minimumProtocolVersion))
        );
        protocolVersionsProxy.changeAdmin(proxyAdmin);

        vm.stopBroadcast();

        _postCheck();
        _writeAddress();
    }

    function _postCheck() internal view {
        address proxy = address(protocolVersionsProxy);
        require(proxy.code.length != 0, "protocol versions proxy not deployed");
        require(_slotAddress(proxy, ADMIN_SLOT) == proxyAdmin, "proxy admin mismatch");
        require(_slotAddress(proxy, IMPLEMENTATION_SLOT) == protocolVersionsImpl, "proxy implementation mismatch");

        IProtocolVersions registry = IProtocolVersions(proxy);
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

    function _writeAddress() internal {
        console.log("ProtocolVersions proxy:", address(protocolVersionsProxy));
        vm.writeJson(vm.toString(address(protocolVersionsProxy)), addressesJson, ".protocolVersionsProxy");
        vm.writeJson(vm.toString(abi.encode(deployer)), addressesJson, ".protocolVersionsProxyConstructorArgs");
    }

    function _slotAddress(address target, bytes32 slot) internal view returns (address) {
        return address(uint160(uint256(vm.load(target, slot))));
    }
}
