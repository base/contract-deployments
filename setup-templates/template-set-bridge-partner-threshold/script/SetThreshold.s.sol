// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface IBridgeValidator {
    function setPartnerThreshold(uint256 newThreshold) external;
}

contract SetThreshold is MultisigScript {
    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address public immutable L1_PORTAL = vm.envAddress("L1_PORTAL");
    address public immutable L2_BRIDGE_VALIDATOR = vm.envAddress("L2_BRIDGE_VALIDATOR");
    uint256 public immutable NEW_THRESHOLD = vm.envUint("NEW_THRESHOLD");

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        address to = L2_BRIDGE_VALIDATOR;
        uint256 value = 0;
        uint64 gasLimit = 100_000;
        bool isCreation = false;
        bytes memory data = abi.encodeCall(IBridgeValidator.setPartnerThreshold, (NEW_THRESHOLD));

        calls[0] = IMulticall3.Call3Value({
            target: L1_PORTAL,
            allowFailure: false,
            callData: abi.encodeCall(IOptimismPortal2.depositTransaction, (to, value, gasLimit, isCreation, data)),
            value: value
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
