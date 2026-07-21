include ../../Makefile
include ../../Multisig.mk

TASK_ID ?= 2026-07-10-transfer-systemconfig-ownership
TASK_NETWORK ?= zeronet
TASK_DIR = tasks/$(TASK_ID)
TASK_CONFIG_DIR = $(TASK_DIR)/config/$(TASK_NETWORK)

include $(TASK_CONFIG_DIR)/network.env
include $(TASK_CONFIG_DIR)/.env

export PROXY_ADMIN_OWNER
export INCIDENT_MULTISIG
export SYSTEM_CONFIG

SIGNER_TOOL_PATH = $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR = $(CURDIR)/$(TASK_CONFIG_DIR)/validations
PROJECT_DIR = $(CURDIR)/$(TASK_CONFIG_DIR)
RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = --root $(TASK_CONFIG_DIR) $(TASK_CONFIG_DIR)/script/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership

.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(CB_MULTISIG),$(VALIDATION_SENDER),base-signer.json,PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

.PHONY: gen-validation-sc
gen-validation-sc: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),$(BASE_SECURITY_COUNCIL),$(VALIDATION_SENDER),security-council-signer.json,PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG))

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_MULTISIG),$(SIGNATURES))

.PHONY: approve-sc
approve-sc:
	$(call MULTISIG_APPROVE,$(BASE_SECURITY_COUNCIL),$(SIGNATURES))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
