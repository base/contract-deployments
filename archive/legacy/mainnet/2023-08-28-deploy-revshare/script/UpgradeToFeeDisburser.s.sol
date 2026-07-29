// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";

import { Proxy } from "@eth-optimism-bedrock/contracts/universal/Proxy.sol";

import { MultisigBuilder } from "@base-contracts/script/universal/MultisigBuilder.sol";
import { FeeDisburser } from "@base-contracts/src/revenue-share/FeeDisburser.sol";

/**
 * @notice Upgrades the FeeDisburser proxy contract
 */
contract UpgradeToFeeDisburser is MultisigBuilder {
    address payable internal FEE_DISBURSER_PROXY = payable(vm.envAddress("FEE_DISBURSER_PROXY"));
    address payable internal FEE_DISBURSER_IMPL = payable(vm.envAddress("FEE_DISBURSER_IMPL"));
    address internal OPTIMISM_WALLET = vm.envAddress("OPTIMISM_WALLET");
    address internal CB_SAFE_ADDR = vm.envAddress("L2_CB_SAFE_ADDR");

    /**
     * @notice Upgrades the FeeDisburser proxy to point to the FeeDisburser implementation contract
     */
    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        ///
        // FEE DISBURSER PROXY UPGRADE TO FEE DISBURSER IMPLEMENTATION CALL
        ///
        calls[0] = IMulticall3.Call3({
            target: FEE_DISBURSER_PROXY,
            allowFailure: false,
            callData: abi.encodeCall(
                Proxy.upgradeTo,
                (
                    FEE_DISBURSER_IMPL
                )
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return CB_SAFE_ADDR;
    }

    /**
     * @notice Checks that the FeeDisburser proxy is able to read an immutable variable on the FeeDisburser implementation contract.
     */
    function _postCheck() internal override view {
        require(
            FeeDisburser(FEE_DISBURSER_PROXY).OPTIMISM_WALLET() == OPTIMISM_WALLET,
            "UpgradeToFeeDisburser: FeeDisburser incorrect Optimism Wallet"
        );
    }
}
