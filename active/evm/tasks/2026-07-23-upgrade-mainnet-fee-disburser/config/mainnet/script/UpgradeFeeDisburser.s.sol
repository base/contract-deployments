// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/scripts/universal/IGnosisSafe.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

interface IFeeDisburser {
    function initialize(address payable[] memory systemAddresses, uint256[] memory targetBalances) external;
}

interface IOptimismPortal2 {
    function depositTransaction(address to, uint256 value, uint64 gasLimit, bool isCreation, bytes memory data)
        external
        payable;
}

interface IProxy {
    function upgradeToAndCall(address implementation, bytes memory data) external payable returns (bytes memory);
}

contract UpgradeFeeDisburser is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable OPTIMISM_PORTAL;
    address internal immutable FEE_DISBURSER;
    address internal immutable FEE_DISBURSER_IMPL;
    uint64 internal immutable L2_GAS_LIMIT;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        OPTIMISM_PORTAL = vm.envAddress("OPTIMISM_PORTAL");
        FEE_DISBURSER = vm.envAddress("FEE_DISBURSER");
        FEE_DISBURSER_IMPL = vm.envAddress("FEE_DISBURSER_IMPL_ADDR");
        uint256 l2GasLimit = vm.envUint("L2_GAS_LIMIT");
        require(l2GasLimit <= type(uint64).max, "L2 gas limit too large");
        L2_GAS_LIMIT = uint64(l2GasLimit);

        require(FEE_DISBURSER_IMPL != address(0), "implementation not set");
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal override {}

    function _buildCalls() internal view override returns (Call[] memory calls) {
        address payable[] memory systemAddresses = new address payable[](0);
        uint256[] memory targetBalances = new uint256[](0);
        bytes memory initializeCall = abi.encodeCall(IFeeDisburser.initialize, (systemAddresses, targetBalances));
        bytes memory upgradeCall = abi.encodeCall(IProxy.upgradeToAndCall, (FEE_DISBURSER_IMPL, initializeCall));

        calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: OPTIMISM_PORTAL,
            data: abi.encodeCall(
                IOptimismPortal2.depositTransaction, (FEE_DISBURSER, 0, L2_GAS_LIMIT, false, upgradeCall)
            ),
            value: 0
        });
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
