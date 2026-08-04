include ../../Makefile
include ../../Multisig.mk

TASK_NETWORK ?= zeronet
TASK_ID ?= 2026-07-10-transfer-systemconfig-ownership
TASK_DIR = tasks/$(TASK_ID)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include $(TASK_DIR)/config/$(TASK_NETWORK)/.env

export BASE_CONTRACTS_COMMIT
export PROXY_ADMIN_OWNER
export INCIDENT_MULTISIG
export SYSTEM_CONFIG
export RECORD_STATE_DIFF
export FOUNDRY_BROADCAST = $(TASK_DIR)

SIGNER_TOOL_PATH = ../../signer-tool
VALIDATIONS_DIR = $(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)/validations
# Task-origin signatures are stored OUTSIDE the config directory, at
# tasks/<task-id>/signatures/<network>/. The signer tool signs over the
# config/<network> tarball (TASK_ORIGIN_DIR); keeping signatures out of that
# directory ensures generating them does not change the signed payload.
TASK_ORIGIN_DIR = $(CURDIR)/$(TASK_DIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR = $(CURDIR)/$(TASK_DIR)/signatures/$(TASK_NETWORK)
RPC_URL = $(L1_RPC_URL)

SCRIPT_NAME = script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership
CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
TRANSFER_OWNERSHIP_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG) RECORD_STATE_DIFF=$(RECORD_STATE_DIFF)

.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(CB_SENDER),base-signer.json,$(TRANSFER_OWNERSHIP_ENV))

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(SC_SENDER),security-council-signer.json,$(TRANSFER_OWNERSHIP_ENV))

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
