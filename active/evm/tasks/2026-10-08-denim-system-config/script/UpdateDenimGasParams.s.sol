// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface ISystemConfig {
    function owner() external view returns (address);
    function gasLimit() external view returns (uint64);
    function minimumGasLimit() external view returns (uint64);
    function maximumGasLimit() external view returns (uint64);
    function eip1559Denominator() external view returns (uint32);
    function eip1559Elasticity() external view returns (uint32);
    function daFootprintGasScalar() external view returns (uint16);
    function setGasLimit(uint64 _gasLimit) external;
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
}

/// @notice Writes the post-Denim gas limit and EIP-1559 denominator to SystemConfig.
/// @dev At the first Denim block the node scales both values itself (gas limit / 10, denominator x 10)
///      to keep throughput and base-fee responsiveness per second at 200ms blocks. This task records
///      the same values on L1 so that a later SystemConfig update does not restore the 2s-block ones.
///      It must execute after Denim activates: before it, the node would scale the new values again.
contract UpdateDenimGasParams is MultisigScript {
    address internal immutable ownerSafe;
    address internal immutable systemConfig;
    uint256 internal immutable denimActivationTimestamp;

    uint64 internal immutable oldGasLimit;
    uint64 internal immutable newGasLimit;
    uint32 internal immutable oldDenominator;
    uint32 internal immutable newDenominator;

    /// @dev Live values captured at construction and re-asserted after execution.
    uint32 internal immutable elasticity;
    uint16 internal immutable daFootprintGasScalar;

    constructor() {
        ownerSafe = vm.envAddress("CB_MULTISIG");
        systemConfig = vm.envAddress("SYSTEM_CONFIG");
        denimActivationTimestamp = vm.envUint("DENIM_ACTIVATION_TIMESTAMP");

        oldGasLimit = uint64(vm.envUint("OLD_GAS_LIMIT"));
        newGasLimit = uint64(vm.envUint("NEW_GAS_LIMIT"));
        oldDenominator = uint32(vm.envUint("OLD_EIP1559_DENOMINATOR"));
        newDenominator = uint32(vm.envUint("NEW_EIP1559_DENOMINATOR"));

        ISystemConfig config = ISystemConfig(systemConfig);
        elasticity = config.eip1559Elasticity();
        daFootprintGasScalar = config.daFootprintGasScalar();
    }

    function setUp() public view {
        ISystemConfig config = ISystemConfig(systemConfig);

        require(config.owner() == ownerSafe, "system config owner mismatch");
        require(config.gasLimit() == oldGasLimit, "unexpected current gas limit");
        require(config.eip1559Denominator() == oldDenominator, "unexpected current denominator");

        require(newGasLimit * 10 == oldGasLimit, "new gas limit is not old / 10");
        require(newDenominator == oldDenominator * 10, "new denominator is not old x 10");
        require(newGasLimit >= config.minimumGasLimit(), "new gas limit below minimum");
        require(newGasLimit <= config.maximumGasLimit(), "new gas limit above maximum");

        require(block.timestamp >= denimActivationTimestamp, "Denim not active yet");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](2);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: systemConfig,
            data: abi.encodeCall(ISystemConfig.setGasLimit, (newGasLimit)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: systemConfig,
            data: abi.encodeCall(ISystemConfig.setEIP1559Params, (newDenominator, elasticity)),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        ISystemConfig config = ISystemConfig(systemConfig);

        require(config.gasLimit() == newGasLimit, "gas limit not updated");
        require(config.eip1559Denominator() == newDenominator, "denominator not updated");
        require(config.eip1559Elasticity() == elasticity, "elasticity changed");
        require(config.daFootprintGasScalar() == daFootprintGasScalar, "DA footprint gas scalar changed");
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
