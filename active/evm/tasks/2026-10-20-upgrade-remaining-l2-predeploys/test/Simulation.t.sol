// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {UpgradeL2Predeploys} from "../script/UpgradeL2Predeploys.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {L2UpgradeTest} from "./L2Upgrade.t.sol";

contract SimulationHarness is UpgradeL2Predeploys {
    function simulateForTest() external {
        address[] memory safes = new address[](1);
        safes[0] = ownerSafe;
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory payload) =
            _simulateForSigner(safes, _buildCallsChain(safes));
        _postCheck(accesses, payload);
    }
}

contract SimulationTest is L2UpgradeTest {
    function testL1MultisigSimulation() public {
        address[4] memory impls = _implementations();
        string[4] memory keys =
            [string("ERC721_FACTORY_IMPL"), "OPERATOR_FEE_VAULT_IMPL", "SCHEMA_REGISTRY_IMPL", "EAS_IMPL"];
        for (uint256 i; i < 4; i++) {
            vm.makePersistent(impls[i]);
            vm.setEnv(keys[i], vm.toString(impls[i]));
        }
        vm.createSelectFork(vm.envString("L1_RPC_URL"));
        SimulationHarness upgrade = new SimulationHarness();
        upgrade.setUp();
        vm.prank(vm.envAddress("CB_MULTISIG"));
        upgrade.simulateForTest();
    }
}
