// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IProtocolVersions {
    function FREEZE_WINDOW() external view returns (uint64);
    function MIN_NOTICE() external view returns (uint64);
    function getSchedule() external view returns (uint64[] memory);
    function minimumProtocolVersion() external view returns (uint256);
    function proxyAdminOwner() external view returns (address);
    function scheduleId() external view returns (bytes32);
    function scheduleId(uint256 id) external view returns (bytes32);
    function setTimestamp(uint256 id, uint64 timestamp) external;
}

/// @notice Delays Cobalt activation from 18:00 UTC to 20:00 UTC on Zeronet.
contract DelayCobaltActivation is MultisigScript {
    uint256 internal constant COBALT_UPGRADE_ID = 12;
    uint256 internal constant EXPECTED_SCHEDULE_LENGTH = 13;

    address internal immutable ownerSafe;
    IProtocolVersions internal immutable protocolVersions;
    uint64 internal immutable currentCobaltActivationTimestamp;
    uint64 internal immutable newCobaltActivationTimestamp;
    uint256 internal immutable expectedMinimumProtocolVersion;
    bytes32 internal immutable schedulePrefix;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        protocolVersions = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS_PROXY"));

        uint256 currentTimestamp = vm.envUint("CURRENT_COBALT_ACTIVATION_TIMESTAMP");
        uint256 newTimestamp = vm.envUint("NEW_COBALT_ACTIVATION_TIMESTAMP");
        require(currentTimestamp <= type(uint64).max && newTimestamp <= type(uint64).max, "timestamp overflow");
        currentCobaltActivationTimestamp = uint64(currentTimestamp);
        newCobaltActivationTimestamp = uint64(newTimestamp);

        expectedMinimumProtocolVersion = vm.envUint("EXPECTED_MINIMUM_PROTOCOL_VERSION");

        require(address(protocolVersions).code.length != 0, "protocol versions not deployed");
        schedulePrefix = protocolVersions.scheduleId(COBALT_UPGRADE_ID - 1);
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(protocolVersions),
            data: abi.encodeCall(IProtocolVersions.setTimestamp, (COBALT_UPGRADE_ID, newCobaltActivationTimestamp)),
            value: 0
        });

        return calls;
    }

    function _preCheck() internal view {
        require(protocolVersions.proxyAdminOwner() == ownerSafe, "proxy admin owner mismatch");

        uint64[] memory schedule = protocolVersions.getSchedule();
        require(schedule.length == EXPECTED_SCHEDULE_LENGTH, "unexpected schedule length");
        require(schedule[COBALT_UPGRADE_ID] == currentCobaltActivationTimestamp, "cobalt activation mismatch");
        require(
            protocolVersions.minimumProtocolVersion() == expectedMinimumProtocolVersion,
            "minimum protocol version mismatch"
        );
        require(
            protocolVersions.scheduleId()
                == keccak256(abi.encode(schedulePrefix, COBALT_UPGRADE_ID, currentCobaltActivationTimestamp)),
            "schedule commitment mismatch"
        );

        require(newCobaltActivationTimestamp > currentCobaltActivationTimestamp, "cobalt activation not delayed");
        require(
            block.timestamp + protocolVersions.FREEZE_WINDOW() < currentCobaltActivationTimestamp,
            "cobalt activation is frozen"
        );
        require(
            newCobaltActivationTimestamp >= block.timestamp + protocolVersions.MIN_NOTICE(),
            "insufficient activation notice"
        );
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(protocolVersions.proxyAdminOwner() == ownerSafe, "proxy admin owner changed");

        uint64[] memory schedule = protocolVersions.getSchedule();
        require(schedule.length == EXPECTED_SCHEDULE_LENGTH, "schedule length changed");
        require(schedule[COBALT_UPGRADE_ID] == newCobaltActivationTimestamp, "cobalt activation not updated");
        require(
            protocolVersions.minimumProtocolVersion() == expectedMinimumProtocolVersion,
            "minimum protocol version changed"
        );
        require(
            protocolVersions.scheduleId()
                == keccak256(abi.encode(schedulePrefix, COBALT_UPGRADE_ID, newCobaltActivationTimestamp)),
            "schedule commitment not updated"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
