// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";

interface ITest {
    function counter() external view returns (uint256);
    function increment() external;
}

contract NestedMultisigBuilderScript is NestedMultisigBuilder {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal TARGET = vm.envAddress("TARGET");

    uint256 private COUNT;

    function setUp() external {
        // TODO: Add any pre-check assertions here
        COUNT = ITest(TARGET).counter();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory)
        internal
        view
        override
    {
        // TODO: Add any post-check assertions here
        require(ITest(TARGET).counter() == COUNT + 1, "Counter did not increment");
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] =
            IMulticall3.Call3({target: TARGET, allowFailure: false, callData: abi.encodeCall(ITest.increment, ())});

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return OWNER_SAFE;
    }
}
