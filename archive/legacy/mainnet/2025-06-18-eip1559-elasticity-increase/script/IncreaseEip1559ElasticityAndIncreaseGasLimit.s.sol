// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function eip1559Elasticity() external view returns (uint32);
    function eip1559Denominator() external view returns (uint32);
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
    function gasLimit() external view returns (uint64);
    function setGasLimit(uint64 _gasLimit) external;
}

contract IncreaseEip1559ElasticityAndIncreaseGasLimitScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint32 internal constant DENOMINATOR = 50;
    uint32 internal constant ELASTICITY = 2;
    uint32 internal constant NEW_ELASTICITY = 3;
    uint64 internal constant GAS_LIMIT = 140000000;
    uint64 internal constant NEW_GAS_LIMIT = 150000000;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
    }

    function setUp() external view {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), ELASTICITY, "Elasticity mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).gasLimit(), GAS_LIMIT, "Gas Limit mismatch");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), NEW_ELASTICITY, "Elasticity mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).gasLimit(), NEW_GAS_LIMIT, "Gas Limit mismatch");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setEIP1559Params, (DENOMINATOR, NEW_ELASTICITY)),
            value: 0
        });

        calls[1] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setGasLimit, (NEW_GAS_LIMIT)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
