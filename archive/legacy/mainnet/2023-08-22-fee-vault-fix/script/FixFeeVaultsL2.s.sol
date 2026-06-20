// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";

import { SequencerFeeVault as SequencerFeeVault_Final } from "@eth-optimism-bedrock/src/L2/SequencerFeeVault.sol";
import { L1FeeVault as L1FeeVault_Final } from "@eth-optimism-bedrock/src/L2/L1FeeVault.sol";
import { BaseFeeVault as BaseFeeVault_Final } from "@eth-optimism-bedrock/src/L2/BaseFeeVault.sol";

import { FeeVault } from "@base-contracts/src/fee-vault-fixes/FeeVault.sol";
import "../lib/base-contracts/script/universal/NestedMultisigBuilder.sol";

/**
 * @notice Upgrades the Fee Vaults through two implementation contracts:
 *  1. The first sets the totalProcessed amount to some "correct" amount
 *  2. The second sets the contract to the final intended implementation
 */
contract FixFeeVaultsL2 is NestedMultisigBuilder {
    ProxyAdmin PROXY_ADMIN = ProxyAdmin(Predeploys.PROXY_ADMIN);

    address payable internal SequencerFeeVault = payable(Predeploys.SEQUENCER_FEE_WALLET);
    address payable internal L1FeeVault = payable(Predeploys.L1_FEE_VAULT);
    address payable internal BaseFeeVault = payable(Predeploys.BASE_FEE_VAULT);

    address internal SequencerFeeVaultImpl_1 = vm.envAddress("SEQUENCER_FEEVAULT_IMPL_INT");
    address internal L1FeeVaultImpl_1 = vm.envAddress("L1_FEEVAULT_IMPL_INT");
    address internal BaseFeeVaultImpl_1 = vm.envAddress("BASE_FEEVAULT_IMPL_INT");

    address payable internal SequencerFeeVaultImpl_Final = payable(vm.envAddress("SEQUENCER_FEEVAULT_IMPL_FINAL"));
    address payable internal L1FeeVaultImpl_Final = payable(vm.envAddress("L1_FEEVAULT_IMPL_FINAL"));
    address payable internal BaseFeeVaultImpl_Final = payable(vm.envAddress("BASE_FEEVAULT_IMPL_FINAL"));

    address internal L2_NESTED_SAFE = vm.envAddress("L2_NESTED_SAFE");

    uint256 internal SEQUENCER_VAULT_TARGET_TOTAL_PROCESSED = vm.envUint("SEQUENCER_VAULT_TARGET_TOTAL_PROCESSED");
    uint256 internal L1_VAULT_TARGET_TOTAL_PROCESSED = vm.envUint("L1_VAULT_TARGET_TOTAL_PROCESSED");
    uint256 internal BASE_VAULT_TARGET_TOTAL_PROCESSED = vm.envUint("BASE_VAULT_TARGET_TOTAL_PROCESSED");

    /**
     * @notice Builds the following calls for each vault:
     *   1. upgradeAndCall to intermediate implementation
     *   2. upgrade to final implementation (w/ init as necessary)
     */
    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](6);

        bytes memory setTotalProcessedSequencer = abi.encodeCall(
            FeeVault.setTotalProcessed, (SEQUENCER_VAULT_TARGET_TOTAL_PROCESSED)
        );

        bytes memory setTotalProcessedL1 = abi.encodeCall(
            FeeVault.setTotalProcessed, (L1_VAULT_TARGET_TOTAL_PROCESSED)
        );

        bytes memory setTotalProcessedBase = abi.encodeCall(
            FeeVault.setTotalProcessed, (BASE_VAULT_TARGET_TOTAL_PROCESSED)
        );

        ///
        // SEQUENCER FEE VAULT CALLS
        ///
        calls[0] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgradeAndCall,
                (
                    SequencerFeeVault,
                    SequencerFeeVaultImpl_1,
                    setTotalProcessedSequencer
                )
            )
        });

        calls[1] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgrade,
                (
                    SequencerFeeVault,
                    SequencerFeeVaultImpl_Final
                )
            )
        });

        ///
        // L1 FEE VAULT CALLS
        ///
        calls[2] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgradeAndCall,
                (
                    L1FeeVault,
                    L1FeeVaultImpl_1,
                    setTotalProcessedL1
                )
            )
        });

        calls[3] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgrade,
                (
                    L1FeeVault,
                    L1FeeVaultImpl_Final
                )
            )
        });

        ///
        // BASE FEE VAULT CALLS
        ///
        calls[4] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgradeAndCall,
                (
                    BaseFeeVault,
                    BaseFeeVaultImpl_1,
                    setTotalProcessedBase
                )
            )
        });

        calls[5] = IMulticall3.Call3({
            target: Predeploys.PROXY_ADMIN,
            allowFailure: false,
            callData: abi.encodeCall(
                PROXY_ADMIN.upgrade,
                (
                    BaseFeeVault,
                    BaseFeeVaultImpl_Final
                )
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return L2_NESTED_SAFE;
    }

    /**
     * @notice Checks for the following conditions:
     *   1. The new implementation codehash matches the intended
     *   2. The "totalProcessed" amount matches the target
     */
    function _postCheck() internal override view {
        require(
            PROXY_ADMIN.getProxyImplementation(SequencerFeeVault).codehash == SequencerFeeVaultImpl_Final.codehash,
            "FixFeeVaultsL2: SequencerFeeVault not upgraded"
        );
        require(
            SequencerFeeVault_Final(SequencerFeeVault).totalProcessed() == SEQUENCER_VAULT_TARGET_TOTAL_PROCESSED,
            "FixFeeVaultsL2: SequencerFeeVault incorrect total processed"
        );

        require(
            PROXY_ADMIN.getProxyImplementation(L1FeeVault).codehash == L1FeeVaultImpl_Final.codehash,
            "FixFeeVaultsL2: L1FeeVault not upgraded"
        );
        require(
            L1FeeVault_Final(L1FeeVault).totalProcessed() == L1_VAULT_TARGET_TOTAL_PROCESSED,
            "FixFeeVaultsL2: L1FeeVault incorrect total processed"
        );

        require(
            PROXY_ADMIN.getProxyImplementation(BaseFeeVault).codehash == BaseFeeVaultImpl_Final.codehash,
            "FixFeeVaultsL2: BaseFeeVault not upgraded"
        );
        require(
            BaseFeeVault_Final(BaseFeeVault).totalProcessed() == BASE_VAULT_TARGET_TOTAL_PROCESSED,
            "FixFeeVaultsL2: BaseFeeVault incorrect total processed"
        );
    }
}
