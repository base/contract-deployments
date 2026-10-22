include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required on the command line, e.g. make TASK_NETWORK=<network> $(MAKECMDGOALS))
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK must not be empty)
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)
TASK_DIR := tasks/2026-10-21-replace-balance-tracker

DEPLOY_L1_SCRIPT := $(TASK_DIR)/script/DeployBalanceTracker.s.sol:DeployBalanceTracker
DEPLOY_L2_SCRIPT := $(TASK_DIR)/script/DeployFeeDisburser.s.sol:DeployFeeDisburser
SCRIPT_NAME := $(TASK_DIR)/script/UpgradeFeeDisburser.s.sol:UpgradeFeeDisburser

SENDER = $(shell $(MISE_EXEC) cast call $(OWNER_SAFE) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
deployed = $(shell jq -er '.$(1)' $(ADDRESSES_JSON) 2>/dev/null)
require_deployed = @jq -e '[$(1)] | all(.[]; type == "string" and test("^0x[0-9a-fA-F]{40}$$"))' "$(ADDRESSES_JSON)" >/dev/null 2>&1 || \
	{ echo '$(2)'; exit 1; }

DEPLOY_L1_ENV = PROFIT_WALLET=$(PROFIT_WALLET) \
	NEW_ADMIN=$(NEW_ADMIN) \
	SYSTEM_ADDRESS_0=$(SYSTEM_ADDRESS_0) \
	TARGET_BALANCE_0=$(TARGET_BALANCE_0) \
	SYSTEM_ADDRESS_1=$(SYSTEM_ADDRESS_1) \
	TARGET_BALANCE_1=$(TARGET_BALANCE_1)

UPGRADE_ENV = OWNER_SAFE=$(OWNER_SAFE) \
	NEW_ADMIN=$(NEW_ADMIN) \
	NEW_ADMIN_L2_ALIAS=$(NEW_ADMIN_L2_ALIAS) \
	OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	FEE_DISBURSER=$(FEE_DISBURSER) \
	NEW_FEE_DISBURSER_IMPL=$(call deployed,feeDisburserImplementation) \
	NEW_BALANCE_TRACKER=$(call deployed,balanceTracker) \
	L2_RPC_URL=$(L2_RPC_URL)

.PHONY: deps
deps: task-extra-deps

# BalanceTracker imports OpenZeppelin upgradeable contracts through a literal lib/ path. Pin from base/contracts.
.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63

##
# Deployment (facilitator Ledger, no multisig signatures)
##
# The scripts write addresses.json during simulation, before broadcasting, so a failed broadcast can leave only
# some transactions onchain. addresses.json is kept as the checkpoint; RESUME=1 re-sends the unconfirmed
# transactions from the task-scoped broadcast record instead of starting a fresh deployment.
PARTIAL_DEPLOY = Deploy failed; $(ADDRESSES_JSON) is kept. Finish the broadcast with RESUME=1, see FACILITATOR.md.

# Foundry 1.5.1 predates Sepolia's Oct 2026 fork and underprices contract creation by about 7x, so its
# simulated gas limits run out of gas onchain. --skip-simulation sends sequentially with eth_estimateGas limits.
.PHONY: deploy-l1
deploy-l1:
ifndef RESUME
	@test ! -f "$(ADDRESSES_JSON)" || { echo '$(ADDRESSES_JSON) already exists; use RESUME=1 to finish a failed deploy-l1'; exit 1; }
	@echo '{}' > "$(ADDRESSES_JSON)"
endif
	cd $(PROJECT_DIR) && $(DEPLOY_L1_ENV) ADDRESSES_JSON=$(ADDRESSES_JSON) \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_L1_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast --skip-simulation $(if $(RESUME),--resume) -vvvv || { echo "$(PARTIAL_DEPLOY)"; exit 1; }

.PHONY: deploy-l2
deploy-l2:
	$(call require_deployed,.balanceTracker,Run deploy-l1 before deploy-l2)
ifndef RESUME
	@jq -e '.feeDisburserImplementation == null' "$(ADDRESSES_JSON)" >/dev/null || { echo 'FeeDisburser implementation already recorded; use RESUME=1 to finish a failed deploy-l2'; exit 1; }
endif
	cd $(PROJECT_DIR) && FEE_DISBURSER=$(FEE_DISBURSER) FEE_DISBURSEMENT_INTERVAL=$(FEE_DISBURSEMENT_INTERVAL) \
		ADDRESSES_JSON=$(ADDRESSES_JSON) \
		$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(DEPLOY_L2_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast $(if $(RESUME),--resume) -vvvv || { echo "$(PARTIAL_DEPLOY)"; exit 1; }

.PHONY: check-deployments
check-deployments:
	$(call require_deployed,.balanceTracker$(comma) .feeDisburserImplementation,Run deploy-l1 and deploy-l2 first)

##
# Validation and execution (OWNER_SAFE signatures)
##
.PHONY: gen-validation
gen-validation: check-deployments deps-signer-tool
	mkdir -p $(VALIDATIONS_DIR)
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,$(UPGRADE_ENV))

.PHONY: execute
execute: check-deployments
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))

# Run after the deposits are relayed on L2.
.PHONY: verify-l2
verify-l2: check-deployments
	@test "$$($(MISE_EXEC) cast call $(FEE_DISBURSER) 'implementation()(address)' --from 0x0000000000000000000000000000000000000000 --rpc-url $(L2_RPC_URL))" = "$$($(MISE_EXEC) cast to-check-sum-address $(call deployed,feeDisburserImplementation))" \
		&& echo 'FeeDisburser implementation upgraded' || { echo 'FeeDisburser implementation not upgraded'; exit 1; }
	@test "$$($(MISE_EXEC) cast call $(FEE_DISBURSER) 'admin()(address)' --from 0x0000000000000000000000000000000000000000 --rpc-url $(L2_RPC_URL))" = "$$($(MISE_EXEC) cast to-check-sum-address $(NEW_ADMIN_L2_ALIAS))" \
		&& echo 'FeeDisburser admin moved' || { echo 'FeeDisburser admin not moved'; exit 1; }
