// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {DoubleNestedMultisigBuilder} from "@base-contracts/script/universal/DoubleNestedMultisigBuilder.sol";

interface ITest {
    function counter() external view returns (uint256);
    function increment() external;
}

contract DoubleNestedIncrement is DoubleNestedMultisigBuilder {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal TARGET = vm.envAddress("TARGET");

    uint256 private COUNT;

    function setUp() external {
        COUNT = ITest(TARGET).counter();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory)
        internal
        view
        override
    {
        require(ITest(TARGET).counter() == COUNT + 1, "Counter did not increment");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] =
            IMulticall3.Call3({target: TARGET, allowFailure: false, callData: abi.encodeCall(ITest.increment, ())});

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
