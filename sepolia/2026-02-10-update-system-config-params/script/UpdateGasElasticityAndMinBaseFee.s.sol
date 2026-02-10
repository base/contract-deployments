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
    function minBaseFee() external view returns (uint64);
    function setMinBaseFee(uint64 _minBaseFee) external;
    function daFootprintGasScalar() external view returns (uint16);
    function setDAFootprintGasScalar(uint16 _daFootprintGasScalar) external;
}

contract UpdateGasElasticityAndMinBaseFeeScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint64 internal immutable NEW_GAS_LIMIT;
    uint32 internal immutable NEW_ELASTICITY;
    uint32 internal immutable DENOMINATOR;
    uint64 internal immutable NEW_MIN_BASE_FEE;
    uint16 internal immutable NEW_DA_FOOTPRINT_GAS_SCALAR;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");

        NEW_GAS_LIMIT = uint64(vm.envUint("NEW_GAS_LIMIT"));
        NEW_ELASTICITY = uint32(vm.envUint("NEW_ELASTICITY"));
        NEW_MIN_BASE_FEE = uint64(vm.envUint("NEW_MIN_BASE_FEE"));
        NEW_DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("NEW_DA_FOOTPRINT_GAS_SCALAR"));

        // Read the current denominator on-chain; we preserve it unchanged.
        DENOMINATOR = ISystemConfig(SYSTEM_CONFIG).eip1559Denominator();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Denominator(), DENOMINATOR, "Denominator mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).eip1559Elasticity(), NEW_ELASTICITY, "Elasticity mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).gasLimit(), NEW_GAS_LIMIT, "Gas Limit mismatch");
        vm.assertEq(ISystemConfig(SYSTEM_CONFIG).minBaseFee(), NEW_MIN_BASE_FEE, "Min Base Fee mismatch");
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar(),
            NEW_DA_FOOTPRINT_GAS_SCALAR,
            "DA Footprint Gas Scalar mismatch"
        );
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](4);

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

        calls[2] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setMinBaseFee, (NEW_MIN_BASE_FEE)),
            value: 0
        });

        calls[3] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setDAFootprintGasScalar, (NEW_DA_FOOTPRINT_GAS_SCALAR)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
