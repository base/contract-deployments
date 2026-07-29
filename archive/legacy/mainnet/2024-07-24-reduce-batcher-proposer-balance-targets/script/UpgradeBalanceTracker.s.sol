// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";

import { Proxy } from "@eth-optimism-bedrock/src/universal/Proxy.sol";

import { MultisigBuilder, IGnosisSafe, IMulticall3 } from "@base-contracts/script/universal/MultisigBuilder.sol";
import { BalanceTracker } from "@base-contracts/src/revenue-share/BalanceTracker.sol";

/**
 * @notice Upgrades the BalanceTracker proxy contract
 */
contract UpgradeBalanceTracker is MultisigBuilder {
    address internal ownerSafe = vm.envAddress("CB_INCIDENT_SAFE_ADDR");
    address payable internal proxy = payable(vm.envAddress("BALANCE_TRACKER_PROXY"));
    address payable internal implementation = payable(vm.envAddress("BALANCE_TRACKER_IMPLEMENTATION"));

    address payable internal profitWallet = payable(vm.envAddress("PROFIT_WALLET"));
    address payable internal outputProposer = payable(vm.envAddress("OUTPUT_PROPOSER"));
    address payable internal batchSender = payable(vm.envAddress("BATCH_SENDER"));
    uint256 internal outputProposerTargetBalance = vm.envUint("OUTPUT_PROPOSER_TARGET_BALANCE");
    uint256 internal batchSenderTargetBalance = vm.envUint("BATCH_SENDER_TARGET_BALANCE");

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        console.log("Batch Sender: %s", batchSender);
        console.log("Output Proposer: %s", outputProposer);
        console.log("Batch Sender Target Balance: %s", batchSenderTargetBalance);
        console.log("Output Proposer Target Balance: %s", outputProposerTargetBalance);

        address payable[] memory systemAddresses = new address payable[](2);
        uint256[] memory targetBalances = new uint256[](2);
        systemAddresses[0] = outputProposer;
        systemAddresses[1] = batchSender;
        targetBalances[0] = outputProposerTargetBalance;
        targetBalances[1] = batchSenderTargetBalance;

        bytes memory initializeCall = abi.encodeCall(
            BalanceTracker.initialize, (
                systemAddresses,
                targetBalances
            )
        );

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: proxy,
            allowFailure: false,
            callData: abi.encodeCall(
                Proxy.upgradeToAndCall,
                (
                    implementation,
                    initializeCall
                )
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return ownerSafe;
    }

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override {
        vm.prank(ownerSafe);
        require(
            Proxy(proxy).implementation() == implementation,
            "UpgradeBalanceTracker: incorrect proxy implementation"
        );
        require(
            BalanceTracker(implementation).PROFIT_WALLET() == profitWallet,
            "UpgradeBalanceTracker: incorrect profit wallet"
        );
        require(
            BalanceTracker(proxy).systemAddresses(0) == outputProposer,
            "UpgradeBalanceTracker: incorrect output proposer"
        );
        require(
            BalanceTracker(proxy).systemAddresses(1) == batchSender,
            "UpgradeBalanceTracker: incorrect batch sender"
        );
        require(
            BalanceTracker(proxy).targetBalances(0) == outputProposerTargetBalance,
            "UpgradeBalanceTracker: incorrect output proposer target balance"
        );
        require(
            BalanceTracker(proxy).targetBalances(1) == batchSenderTargetBalance,
            "UpgradeBalanceTracker: incorrect batch sender target balance"
        );
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}
