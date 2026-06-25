// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";

import { FeeVault } from "@base-contracts/src/fee-vault-fixes/FeeVault.sol";

import { SequencerFeeVault as SequencerFeeVault_Final } from "@eth-optimism-bedrock/src/L2/SequencerFeeVault.sol";
import { L1FeeVault as L1FeeVault_Final } from "@eth-optimism-bedrock/src/L2/L1FeeVault.sol";
import { FeeVault as OPFeeVault } from "@eth-optimism-bedrock/src/universal/FeeVault.sol";
import { BaseFeeVault as BaseFeeVault_Final } from "@eth-optimism-bedrock/src/L2/BaseFeeVault.sol";

/**
 * @notice Deploys two (2) implementation contracts per fault for a total of six (6)
 *  1. The first contract sets the totalProcessed amount to some "correct" amount
 *  2. The second contract is final intended implementation
 */
contract DeployNewFeeVaultsL2 is Script {
    address internal deployer = vm.envAddress("DEPLOYER");

    function run() public {
        uint256 minWithdrawalAmount = vm.envUint("MIN_WITHDRAWAL_AMOUNT");
        address feeVaultRecipient = vm.envAddress("FEE_VAULT_RECIPIENT");

        // Intermediate implementation contracts
        vm.broadcast(deployer);
        FeeVault sfv = new FeeVault();

        vm.broadcast(deployer);
        FeeVault l1fv = new FeeVault();

        vm.broadcast(deployer);
        FeeVault bfv = new FeeVault();

        // Final implementation contracts
        vm.broadcast(deployer);
        SequencerFeeVault_Final sfv_final = new SequencerFeeVault_Final(
            feeVaultRecipient, 
            minWithdrawalAmount,  
            OPFeeVault.WithdrawalNetwork.L2
        );

        vm.broadcast(deployer);
        L1FeeVault_Final l1fv_final = new L1FeeVault_Final(
            feeVaultRecipient, 
            minWithdrawalAmount,  
            OPFeeVault.WithdrawalNetwork.L2
        );

        vm.broadcast(deployer);
        BaseFeeVault_Final bfv_final = new BaseFeeVault_Final(
            feeVaultRecipient, 
            minWithdrawalAmount,  
            OPFeeVault.WithdrawalNetwork.L2
        );

        console.log("Sequencer Fee Vault (Intermediate): %s", address(sfv));
        console.log("L1 Fee Vault (Intermediate): %s", address(l1fv));
        console.log("Base Fee Vault (Intermediate): %s", address(bfv));

        console.log("Sequencer Fee Vault (Final): %s", address(sfv_final));
        console.log("L1 Fee Vault (Final): %s", address(l1fv_final));
        console.log("Base Fee Vault (Final): %s", address(bfv_final));
    }
}