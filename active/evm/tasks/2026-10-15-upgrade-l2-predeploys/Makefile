include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

# The network is never defaulted or read from the environment. Select it on every command line:
#   make TASK_NETWORK=zeronet deploy
ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json

TASK_DIR := tasks/2026-10-15-upgrade-l2-predeploys
DEPLOY_PREDEPLOYS_SCRIPT := $(TASK_DIR)/script/DeployL2PredeployImpls.s.sol:DeployL2PredeployImpls
DEPLOY_FEE_VAULTS_SCRIPT := $(TASK_DIR)/script/DeployFeeVaultImpls.s.sol:DeployFeeVaultImpls
UPGRADE_SCRIPT := $(TASK_DIR)/script/UpgradeL2Predeploys.s.sol:UpgradeL2Predeploys
SCRIPT_NAME := $(UPGRADE_SCRIPT)

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

impl = $(shell jq -er '.$(1)' $(ADDRESSES_JSON) 2>/dev/null)

UPGRADE_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	OPTIMISM_PORTAL=$(OPTIMISM_PORTAL) \
	L2_RPC_URL=$(L2_RPC_URL) \
	L2_TO_L1_MESSAGE_PASSER_IMPL=$(call impl,l2ToL1MessagePasser) \
	L1_BLOCK_IMPL=$(call impl,l1Block) \
	SEQUENCER_FEE_VAULT_IMPL=$(call impl,sequencerFeeVault) \
	BASE_FEE_VAULT_IMPL=$(call impl,baseFeeVault) \
	L1_FEE_VAULT_IMPL=$(call impl,l1FeeVault) \
	FEE_VAULT_RECIPIENT=$(FEE_VAULT_RECIPIENT) \
	FEE_VAULT_MIN_WITHDRAWAL_AMOUNT=$(FEE_VAULT_MIN_WITHDRAWAL_AMOUNT) \
	FEE_VAULT_WITHDRAWAL_NETWORK=$(FEE_VAULT_WITHDRAWAL_NETWORK)

##
# Deployment
##
# The implementations are deployed on L2 with base/contracts' settings for these contracts: 999999 optimizer runs and
# no bytecode hash.
PREDEPLOY_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999 \
	FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy
deploy:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && ADDRESSES_JSON=$(ADDRESSES_JSON) $(PREDEPLOY_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(DEPLOY_PREDEPLOYS_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
	cd $(PROJECT_DIR) && ADDRESSES_JSON=$(ADDRESSES_JSON) $(PREDEPLOY_BUILD) \
		$(MISE_EXEC) forge script --rpc-url $(L2_RPC_URL) $(DEPLOY_FEE_VAULTS_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

##
# Validation files
##
.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(UPGRADE_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(UPGRADE_SCRIPT),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(UPGRADE_ENV))

##
# Approve and execute
##
.PHONY: approve-cb
approve-cb:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	export $(UPGRADE_ENV); $(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	export $(UPGRADE_ENV); $(call MULTISIG_EXECUTE,0x)
