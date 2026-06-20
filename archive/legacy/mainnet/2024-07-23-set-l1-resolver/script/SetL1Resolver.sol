// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    MultisigBuilder,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";
import { Vm } from "forge-std/Vm.sol";

interface Registry {
    function setResolver(bytes32 node, address resolver) external;
    function resolver(bytes32 node) external returns (address);
}

contract SetL1Resolver is MultisigBuilder {

    address internal ENS_REGISTRY = vm.envAddress("ENS_REGISTRY");
    address internal INCIDENT_MULTISIG = vm.envAddress("L1_INCIDENT_MULTISIG");
    bytes32 internal BASE_ETH_NODE = vm.envBytes32("BASE_ETH_NODEHASH");
    address internal L1_RESOLVER_ADDR = vm.envAddress("L1_RESOLVER_ADDR");

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override {
        assert(Registry(ENS_REGISTRY).resolver(BASE_ETH_NODE) == L1_RESOLVER_ADDR);
    }

    /**
     * @notice Creates the calldata
     */
    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: ENS_REGISTRY,
            allowFailure: false,
            callData: abi.encodeCall(Registry.setResolver, (BASE_ETH_NODE, L1_RESOLVER_ADDR))
        });

        return calls;
    }

    /**
     * @notice Returns the safe address to execute the transaction from
     */
    function _ownerSafe() internal override view returns (address) {
        return INCIDENT_MULTISIG;
    }

    function _addOverrides(address _safe) internal override view returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }
}