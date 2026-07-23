export FEE_DISBURSER
export FEE_DISBURSER_IMPL_ADDR
export FEE_DISBURSEMENT_INTERVAL
export OWNER_SAFE
export OPTIMISM_PORTAL
export L2_GAS_LIMIT

TASK_ORIGIN_DIR = $(CURDIR)/$(TASK_CONFIG_DIR)
SIGNATURE_DIR = $(CURDIR)/$(TASK_DIR)/signatures/$(TASK_NETWORK)

FEE_DISBURSER_DEPLOY_SCRIPT = --root $(TASK_CONFIG_DIR) $(TASK_CONFIG_DIR)/script/DeployFeeDisburser.s.sol:DeployFeeDisburser
FEE_DISBURSER_UPGRADE_SCRIPT = --root $(TASK_CONFIG_DIR) $(TASK_CONFIG_DIR)/script/UpgradeFeeDisburser.s.sol:UpgradeFeeDisburser

.PHONY: deploy-fee-disburser
deploy-fee-disburser:
	$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(FEE_DISBURSER_DEPLOY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

.PHONY: gen-validation-fee-disburser
gen-validation-fee-disburser: deps-signer-tool
	$(call GEN_VALIDATION,$(FEE_DISBURSER_UPGRADE_SCRIPT),,$(VALIDATION_SENDER),base-signer.json,)

.PHONY: execute-fee-disburser
execute-fee-disburser: SCRIPT_NAME := $(FEE_DISBURSER_UPGRADE_SCRIPT)
execute-fee-disburser:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
