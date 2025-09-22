// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ITest {
    function counter() external view returns (uint256);
    function increment() external;
}

contract CounterMultisigScript is MultisigScript {
    address internal OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal TARGET = vm.envAddress("TARGET");

    uint256 private COUNT;

    function setUp() external {
        // TODO: Add any pre-check assertions here
        COUNT = ITest(TARGET).counter();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        // TODO: Add any post-check assertions here
        require(ITest(TARGET).counter() == COUNT + 1, "Counter did not increment");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        calls[0] = IMulticall3.Call3Value({
            target: TARGET,
            allowFailure: false,
            callData: abi.encodeCall(ITest.increment, ()),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
