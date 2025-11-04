// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";

interface ISystemConfig {
    function daFootprintGasScalar() external view returns (uint16);
    function minBaseFee() external view returns (uint64);
    function setDAFootprintGasScalar(uint16 _daFootprintGasScalar) external;
    function setMinBaseFee(uint64 _minBaseFee) external;
}

contract SetJovianParametersScript is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable SYSTEM_CONFIG;

    uint16 internal immutable DA_FOOTPRINT_GAS_SCALAR;
    uint64 internal immutable MIN_BASE_FEE;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        SYSTEM_CONFIG = vm.envAddress("SYSTEM_CONFIG");
        DA_FOOTPRINT_GAS_SCALAR = uint16(vm.envUint("DA_FOOTPRINT_GAS_SCALAR"));
        MIN_BASE_FEE = uint64(vm.envUint("MIN_BASE_FEE"));
    }

    function setUp() external view {
        // Log current values for reference
        console.log("Current DA Footprint Gas Scalar:", ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar());
        console.log("Current Min Base Fee:", ISystemConfig(SYSTEM_CONFIG).minBaseFee());
        console.log("New DA Footprint Gas Scalar:", DA_FOOTPRINT_GAS_SCALAR);
        console.log("New Min Base Fee:", MIN_BASE_FEE);
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).daFootprintGasScalar(),
            DA_FOOTPRINT_GAS_SCALAR,
            "DA Footprint Gas Scalar mismatch"
        );
        vm.assertEq(
            ISystemConfig(SYSTEM_CONFIG).minBaseFee(),
            MIN_BASE_FEE,
            "Min Base Fee mismatch"
        );
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        calls[0] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setDAFootprintGasScalar, (DA_FOOTPRINT_GAS_SCALAR)),
            value: 0
        });

        calls[1] = IMulticall3.Call3Value({
            target: SYSTEM_CONFIG,
            allowFailure: false,
            callData: abi.encodeCall(ISystemConfig.setMinBaseFee, (MIN_BASE_FEE)),
            value: 0
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
