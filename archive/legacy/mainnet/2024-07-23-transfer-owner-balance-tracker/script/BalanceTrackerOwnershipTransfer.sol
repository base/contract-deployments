// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Vm } from "forge-std/Vm.sol";
import { Proxy } from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe
} from "@base-contracts/script/universal/MultisigBuilder.sol";

contract BalanceTrackerOwnershipTransfer is MultisigBuilder {
    address internal _proxyContract = vm.envAddress("BALANCE_TRACKER_PROXY_ADDR");
    address internal _oldOwner = vm.envAddress("CB_UPGRADE_SAFE_ADDR");
    address internal _newOwner = vm.envAddress("CB_INCIDENT_SAFE_ADDR");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override {
        Proxy proxy = Proxy(payable(_proxyContract));
        vm.prank(_newOwner);
        assert(proxy.admin() == _newOwner);
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: _proxyContract,
            allowFailure: false,
            callData: abi.encodeCall(Proxy.changeAdmin, (_newOwner))
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return _oldOwner;
    }

    function _addOverrides(address _safe) internal view override returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}
