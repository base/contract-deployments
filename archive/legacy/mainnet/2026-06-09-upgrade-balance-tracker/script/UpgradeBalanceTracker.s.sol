// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {MultisigScript} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {Enum} from "@base-contracts/scripts/universal/IGnosisSafe.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";
import {BalanceTracker} from "@base-contracts/src/L1/BalanceTracker.sol";

/// @title UpgradeBalanceTracker
/// @notice Upgrades the L1 BalanceTracker proxy to a new implementation and re-initializes its
///         system addresses / target balances so that it tops up the batch sender, proposer,
///         challenger, and registrar addresses.
///
///         `systemAddresses` / `targetBalances` can only be set via `initialize`, which is guarded
///         by `reinitializer(3)`. The proxy is currently at initialized version 2, so this upgrade
///         points the proxy at a new implementation (deployed by `DeployBalanceTracker`, read from
///         addresses.json) and calls `initialize` in the same transaction via `upgradeToAndCall`.
///
///         The proxy admin is the CB Incident multisig (`OWNER_SAFE`), which executes this call.
contract UpgradeBalanceTracker is MultisigScript {
    using stdJson for string;

    // Config loaded from .env.
    address internal ownerSafeEnv;
    address payable internal proxyEnv;
    address payable internal batchSenderEnv;
    address payable internal proposerEnv;
    address payable internal challengerEnv;
    address payable internal registrarEnv;
    uint256 internal batchSenderTargetBalanceEnv;
    uint256 internal proposerTargetBalanceEnv;
    uint256 internal challengerTargetBalanceEnv;
    uint256 internal registrarTargetBalanceEnv;

    // Resolved from addresses.json (deployment output) and live onchain state.
    address payable internal implementation;
    address payable internal expectedProfitWallet;

    function setUp() public {
        ownerSafeEnv = vm.envAddress("OWNER_SAFE");
        proxyEnv = payable(vm.envAddress("BALANCE_TRACKER"));
        batchSenderEnv = payable(vm.envAddress("BATCH_SENDER"));
        proposerEnv = payable(vm.envAddress("PROPOSER"));
        challengerEnv = payable(vm.envAddress("CHALLENGER"));
        registrarEnv = payable(vm.envAddress("REGISTRAR"));
        batchSenderTargetBalanceEnv = vm.envUint("BATCH_SENDER_TARGET_BALANCE");
        proposerTargetBalanceEnv = vm.envUint("PROPOSER_TARGET_BALANCE");
        challengerTargetBalanceEnv = vm.envUint("CHALLENGER_TARGET_BALANCE");
        registrarTargetBalanceEnv = vm.envUint("REGISTRAR_TARGET_BALANCE");

        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/addresses.json"));
        implementation = payable(json.readAddress(".balanceTrackerImplementation"));
        require(implementation != address(0), "UpgradeBalanceTracker: implementation not deployed (run `make deploy`)");

        // The new implementation must preserve the profit wallet configured onchain.
        expectedProfitWallet = BalanceTracker(proxyEnv).PROFIT_WALLET();
    }

    /// @notice The new system addresses and their target balances, in a single canonical ordering
    ///         shared by `_buildCalls` and `_postCheck`.
    function _systemConfig()
        internal
        view
        returns (address payable[] memory systemAddresses, uint256[] memory targetBalances)
    {
        systemAddresses = new address payable[](4);
        systemAddresses[0] = batchSenderEnv;
        systemAddresses[1] = proposerEnv;
        systemAddresses[2] = challengerEnv;
        systemAddresses[3] = registrarEnv;

        targetBalances = new uint256[](4);
        targetBalances[0] = batchSenderTargetBalanceEnv;
        targetBalances[1] = proposerTargetBalanceEnv;
        targetBalances[2] = challengerTargetBalanceEnv;
        targetBalances[3] = registrarTargetBalanceEnv;
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        (address payable[] memory systemAddresses, uint256[] memory targetBalances) = _systemConfig();

        console.log("Implementation:", implementation);
        console.log("Batch Sender:", batchSenderEnv, "=>", batchSenderTargetBalanceEnv);
        console.log("Proposer:", proposerEnv, "=>", proposerTargetBalanceEnv);
        console.log("Challenger:", challengerEnv, "=>", challengerTargetBalanceEnv);
        console.log("Registrar:", registrarEnv, "=>", registrarTargetBalanceEnv);

        bytes memory initializeCall = abi.encodeCall(BalanceTracker.initialize, (systemAddresses, targetBalances));

        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyEnv,
            data: abi.encodeCall(Proxy.upgradeToAndCall, (implementation, initializeCall)),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {
        (address payable[] memory systemAddresses, uint256[] memory targetBalances) = _systemConfig();

        vm.prank(ownerSafeEnv);
        require(Proxy(proxyEnv).implementation() == implementation, "UpgradeBalanceTracker: incorrect implementation");

        require(
            BalanceTracker(proxyEnv).PROFIT_WALLET() == expectedProfitWallet,
            "UpgradeBalanceTracker: profit wallet changed"
        );

        for (uint256 i; i < systemAddresses.length; i++) {
            require(
                BalanceTracker(proxyEnv).systemAddresses(i) == systemAddresses[i],
                "UpgradeBalanceTracker: incorrect system address"
            );
            require(
                BalanceTracker(proxyEnv).targetBalances(i) == targetBalances[i],
                "UpgradeBalanceTracker: incorrect target balance"
            );
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafeEnv;
    }
}
