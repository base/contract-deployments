// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Script} from "forge-std/Script.sol";
import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IProtocolVersions {
    function FREEZE_WINDOW() external view returns (uint64);
    function MIN_NOTICE() external view returns (uint64);
    function delayTimestamp(uint256 id, uint64 newTimestamp) external;
    function getSchedule() external view returns (uint64[] memory);
    function incidentResponder() external view returns (address);
    function scheduleId() external view returns (bytes32);
}

contract DelayUpgradeActivation is MultisigScript {
    IProtocolVersions internal immutable protocolVersions;
    address internal immutable ownerSafe;
    uint256 internal immutable upgradeId;
    uint64 internal immutable expectedCurrentTimestamp;
    uint64 internal immutable newTimestamp;
    uint256 internal immutable scheduleLength;
    bytes32 internal immutable originalScheduleHash;

    constructor() {
        protocolVersions = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS_PROXY"));
        upgradeId = vm.envUint("UPGRADE_ID");
        uint256 current = vm.envUint("EXPECTED_CURRENT_TIMESTAMP");
        uint256 next = vm.envUint("NEW_TIMESTAMP");
        require(current <= type(uint64).max && next <= type(uint64).max, "timestamp overflow");
        expectedCurrentTimestamp = uint64(current);
        newTimestamp = uint64(next);
        require(address(protocolVersions).code.length != 0, "protocol versions not deployed");
        ownerSafe = protocolVersions.incidentResponder();
        require(ownerSafe != address(0), "incident responder unset");
        uint64[] memory schedule = protocolVersions.getSchedule();
        scheduleLength = schedule.length;
        originalScheduleHash = keccak256(abi.encode(schedule));
        _preCheck();
    }

    function check() external view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory calls) {
        _preCheck();
        calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(protocolVersions),
            data: abi.encodeCall(IProtocolVersions.delayTimestamp, (upgradeId, newTimestamp)),
            value: 0
        });
    }

    function _preCheck() internal view {
        require(protocolVersions.incidentResponder() == ownerSafe, "incident responder changed");
        uint64[] memory schedule = protocolVersions.getSchedule();
        require(schedule.length == scheduleLength, "schedule length changed");
        require(upgradeId < schedule.length, "unknown upgrade");
        require(schedule[upgradeId] != 0, "upgrade not scheduled");
        require(schedule[upgradeId] == expectedCurrentTimestamp, "activation mismatch");
        require(keccak256(abi.encode(schedule)) == originalScheduleHash, "schedule changed");
        require(protocolVersions.scheduleId() == _commitment(schedule), "schedule commitment mismatch");
        require(newTimestamp > expectedCurrentTimestamp, "activation not delayed");
        require(block.timestamp < expectedCurrentTimestamp, "activation already passed");
        require(block.timestamp + protocolVersions.FREEZE_WINDOW() < expectedCurrentTimestamp, "activation is frozen");
        require(newTimestamp >= block.timestamp + protocolVersions.MIN_NOTICE(), "insufficient activation notice");
        for (uint256 i = upgradeId + 1; i < schedule.length; i++) {
            if (schedule[i] != 0) {
                require(newTimestamp <= schedule[i], "activation exceeds successor");
                break;
            }
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(protocolVersions.incidentResponder() == ownerSafe, "incident responder changed");
        uint64[] memory schedule = protocolVersions.getSchedule();
        require(schedule.length == scheduleLength, "schedule length changed");
        require(schedule[upgradeId] == newTimestamp, "activation not updated");
        require(protocolVersions.scheduleId() == _commitment(schedule), "schedule commitment not updated");
        schedule[upgradeId] = expectedCurrentTimestamp;
        require(keccak256(abi.encode(schedule)) == originalScheduleHash, "unexpected timestamp change");
    }

    function _commitment(uint64[] memory schedule) internal pure returns (bytes32 commitment) {
        for (uint256 i; i < schedule.length; i++) {
            commitment = keccak256(abi.encode(commitment, i, schedule[i]));
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}

contract VerifyUpgradeDelay is Script {
    IProtocolVersions internal immutable protocolVersions = IProtocolVersions(vm.envAddress("PROTOCOL_VERSIONS_PROXY"));
    uint256 internal immutable upgradeId = vm.envUint("UPGRADE_ID");
    uint256 internal immutable newTimestamp = vm.envUint("NEW_TIMESTAMP");
    address internal immutable expectedResponder = vm.envAddress("INCIDENT_MULTISIG");

    function run() external view {
        require(protocolVersions.incidentResponder() == expectedResponder, "incident responder mismatch");
        uint64[] memory schedule = protocolVersions.getSchedule();
        require(upgradeId < schedule.length && schedule[upgradeId] == newTimestamp, "activation not updated");
        bytes32 commitment;
        for (uint256 i; i < schedule.length; i++) {
            commitment = keccak256(abi.encode(commitment, i, schedule[i]));
        }
        require(protocolVersions.scheduleId() == commitment, "schedule commitment mismatch");
    }
}
