// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ProtocolVersions} from "@base-contracts/src/L1/ProtocolVersions.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {DelayUpgradeActivation} from "../script/DelayUpgradeActivation.s.sol";
import {SimulationSafe, SimulationMulticall} from "./SimulationFixtures.sol";

contract DelayHarness is DelayUpgradeActivation {
    function calls() external view returns (Call[] memory) {
        return _buildCalls();
    }

    function responder() external view returns (address) {
        return _ownerSafe();
    }

    function postcheck() external view {
        Vm.AccountAccess[] memory accesses;
        Simulation.Payload memory payload;
        _postCheck(accesses, payload);
    }
}

contract DelayUpgradeActivationTest is Test {
    ProtocolVersions internal protocol;
    address internal constant RESPONDER = address(0xBEEF);
    address internal constant ADMIN = address(0xAD);
    uint256 internal configuredId;
    uint256 internal configuredCurrent;
    uint256 internal configuredNext;

    function setUp() public {
        vm.warp(1000);
        uint64[] memory schedule = new uint64[](13);
        schedule[0] = 10000;
        for (uint256 i = 1; i < schedule.length; i++) {
            schedule[i] = 20000;
        }
        deploy(schedule);
        configure(0, 10000, 15000);
    }

    function deploy(uint64[] memory schedule) internal {
        Proxy proxy = new Proxy(ADMIN);
        ProtocolVersions implementation = new ProtocolVersions();
        vm.prank(ADMIN);
        proxy.upgradeToAndCall(
            address(implementation), abi.encodeCall(ProtocolVersions.initialize, (RESPONDER, schedule, 1))
        );
        protocol = ProtocolVersions(address(proxy));
        vm.setEnv("PROTOCOL_VERSIONS_PROXY", vm.toString(address(protocol)));
    }

    function test_exportValidationFixture() public {
        if (!vm.envOr("EXPORT_VALIDATION_FIXTURE", false)) {
            vm.skip(true);
            return;
        }
        address configuredProxy = vm.envAddress("FIXTURE_PROTOCOL_VERSIONS_PROXY");
        vm.etch(configuredProxy, address(protocol).code);
        vm.store(
            configuredProxy, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1), bytes32(uint256(uint160(ADMIN)))
        );
        uint64[] memory schedule = protocol.getSchedule();
        address implementation = address(new ProtocolVersions());
        vm.prank(ADMIN);
        Proxy(payable(configuredProxy))
            .upgradeToAndCall(implementation, abi.encodeCall(ProtocolVersions.initialize, (RESPONDER, schedule, 1)));
        protocol = ProtocolVersions(configuredProxy);
        configure(
            vm.envUint("FIXTURE_UPGRADE_ID"),
            vm.envUint("FIXTURE_EXPECTED_CURRENT_TIMESTAMP"),
            vm.envUint("FIXTURE_NEW_TIMESTAMP")
        );
        DelayHarness script = newScript();
        MultisigScript.Call[] memory calls = script.calls();
        assertEq(calls.length, 1);
        string memory json = vm.serializeBytes("call", "calldata", calls[0].data);
        json = vm.serializeAddress("call", "target", calls[0].target);
        json = vm.serializeAddress("call", "safe", script.responder());
        json = vm.serializeUint("call", "count", calls.length);
        json = vm.serializeUint("call", "operation", uint256(calls[0].operation));
        json = vm.serializeUint("call", "value", calls[0].value);
        installSimulationFixtures();
        vm.prank(vm.envOr("FIXTURE_SENDER", address(this)));
        script.sign(new address[](0));
        assertEq(protocol.getSchedule()[configuredId], configuredNext);
        vm.writeJson(json, "validation-fixture.json");
    }

    function createScript() external returns (DelayHarness) {
        return newScript();
    }

    function newScript() internal returns (DelayHarness) {
        vm.setEnv("PROTOCOL_VERSIONS_PROXY", vm.toString(address(protocol)));
        vm.setEnv("INCIDENT_MULTISIG", vm.toString(RESPONDER));
        vm.setEnv("UPGRADE_ID", vm.toString(configuredId));
        vm.setEnv("EXPECTED_CURRENT_TIMESTAMP", vm.toString(configuredCurrent));
        vm.setEnv("NEW_TIMESTAMP", vm.toString(configuredNext));
        return new DelayHarness();
    }

    function configure(uint256 id, uint256 current, uint256 next) internal {
        configuredId = id;
        configuredCurrent = current;
        configuredNext = next;
    }

    function installSimulationFixtures() internal {
        vm.etch(RESPONDER, address(new SimulationSafe()).code);
        vm.etch(0xA8B8CA1d6F0F5Ce63dCEA9121A01b302c5801303, address(new SimulationMulticall()).code);
    }

    function test_signSimulationNeedsOnlyLiveResponder() public {
        installSimulationFixtures();
        DelayHarness script = newScript();
        script.sign(new address[](0));
        assertEq(protocol.getSchedule()[0], 15000);
        script.postcheck();
    }

    function test_idZeroBuildsOneDirectResponderCallAndExecutes() public {
        DelayHarness script = newScript();
        MultisigScript.Call[] memory calls = script.calls();
        assertEq(calls.length, 1);
        assertEq(calls[0].target, address(protocol));
        assertEq(uint256(calls[0].operation), uint256(Enum.Operation.Call));
        assertEq(calls[0].value, 0);
        assertEq(calls[0].data, abi.encodeCall(ProtocolVersions.delayTimestamp, (0, 15000)));
        vm.prank(RESPONDER);
        (bool ok,) = calls[0].target.call(calls[0].data);
        assertTrue(ok);
        script.postcheck();
        assertEq(protocol.getSchedule()[0], 15000);
    }

    function test_nonTailCommitmentIncludesUnscheduledHolesAndSuccessors() public {
        uint64[] memory schedule = new uint64[](5);
        schedule[1] = 10000;
        schedule[3] = 20000;
        deploy(schedule);
        configure(1, 10000, 15000);
        DelayHarness script = newScript();
        vm.prank(RESPONDER);
        protocol.delayTimestamp(1, 15000);
        script.postcheck();
        assertEq(protocol.getSchedule()[1], 15000);
        assertEq(protocol.getSchedule()[2], 0);
        configure(2, 0, 15000);
        vm.expectRevert("upgrade not scheduled");
        this.createScript();
    }

    function test_rejectsUnknownUnscheduledWrongExpectedAndNonLater() public {
        configure(99, 10000, 15000);
        vm.expectRevert("unknown upgrade");
        this.createScript();
        configure(0, 9999, 15000);
        vm.expectRevert("activation mismatch");
        this.createScript();
        configure(0, 10000, 10000);
        vm.expectRevert("activation not delayed");
        this.createScript();
        configure(0, 10000, 9999);
        vm.expectRevert("activation not delayed");
        this.createScript();
    }

    function test_rejectsFreezeBoundaryAndAlreadyActivated() public {
        vm.warp(10000 - protocol.FREEZE_WINDOW());
        vm.expectRevert("activation is frozen");
        this.createScript();
        vm.warp(10000);
        vm.expectRevert("activation already passed");
        this.createScript();
    }

    function test_rejectsInsufficientNoticeAndSuccessorOrdering() public {
        vm.mockCall(address(protocol), abi.encodeWithSignature("MIN_NOTICE()"), abi.encode(uint64(20000)));
        vm.expectRevert("insufficient activation notice");
        this.createScript();
        vm.clearMockedCalls();
        configure(0, 10000, 20001);
        vm.expectRevert("activation exceeds successor");
        this.createScript();
    }

    function test_postcheckAcceptsNonTailUpdateWithFullCommitment() public {
        DelayHarness script = newScript();
        vm.prank(RESPONDER);
        protocol.delayTimestamp(0, 15000);
        script.postcheck();
        bytes32 commitment;
        uint64[] memory schedule = protocol.getSchedule();
        for (uint256 i; i < schedule.length; i++) {
            commitment = keccak256(abi.encode(commitment, i, schedule[i]));
        }
        assertEq(protocol.scheduleId(), commitment);
    }

    function test_postcheckRejectsAnotherTimestampChange() public {
        DelayHarness script = newScript();
        vm.prank(RESPONDER);
        protocol.delayTimestamp(0, 15000);
        vm.prank(RESPONDER);
        protocol.delayTimestamp(12, 25000);
        vm.expectRevert("unexpected timestamp change");
        script.postcheck();
    }

    function test_postcheckRejectsResponderAndLengthChanges() public {
        DelayHarness script = newScript();
        vm.prank(RESPONDER);
        protocol.delayTimestamp(0, 15000);
        vm.mockCall(address(protocol), abi.encodeWithSignature("incidentResponder()"), abi.encode(address(0xDEAD)));
        vm.expectRevert("incident responder changed");
        script.postcheck();
        vm.clearMockedCalls();
        uint64[] memory changed = new uint64[](14);
        vm.mockCall(address(protocol), abi.encodeWithSignature("getSchedule()"), abi.encode(changed));
        vm.expectRevert("schedule length changed");
        script.postcheck();
    }

    function test_rejectsCorruptPreAndPostCommitments() public {
        vm.mockCall(address(protocol), abi.encodeWithSignature("scheduleId()"), abi.encode(bytes32(uint256(1))));
        vm.expectRevert("schedule commitment mismatch");
        this.createScript();
        vm.clearMockedCalls();
        DelayHarness script = newScript();
        vm.prank(RESPONDER);
        protocol.delayTimestamp(0, 15000);
        vm.mockCall(address(protocol), abi.encodeWithSignature("scheduleId()"), abi.encode(bytes32(uint256(1))));
        vm.expectRevert("schedule commitment not updated");
        script.postcheck();
    }

    function test_rejectsTimestampOverflow() public {
        configure(0, 10000, uint256(type(uint64).max) + 1);
        vm.expectRevert("timestamp overflow");
        this.createScript();
    }
}
