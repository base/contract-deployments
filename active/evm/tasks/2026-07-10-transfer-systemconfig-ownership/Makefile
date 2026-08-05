TASK_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
EVM_ROOT := $(abspath $(TASK_ROOT)/../..)
CONTRACT_DEPLOYMENTS_ROOT := $(abspath $(EVM_ROOT)/../..)

include $(CONTRACT_DEPLOYMENTS_ROOT)/Makefile
include $(CONTRACT_DEPLOYMENTS_ROOT)/Multisig.mk

TASK_NETWORK ?= zeronet
PROJECT_DIR := $(EVM_ROOT)
FORGE_WORKDIR := $(EVM_ROOT)

include $(CONTRACT_DEPLOYMENTS_ROOT)/config/$(TASK_NETWORK).env
include $(TASK_ROOT)/config/$(TASK_NETWORK)/.env

export BASE_CONTRACTS_COMMIT
export PROXY_ADMIN_OWNER
export INCIDENT_MULTISIG
export SYSTEM_CONFIG
export FOUNDRY_BROADCAST := $(TASK_ROOT)

SIGNER_TOOL_PATH := $(CONTRACT_DEPLOYMENTS_ROOT)/signer-tool
VALIDATIONS_DIR := $(TASK_ROOT)/config/$(TASK_NETWORK)/validations
TASK_ORIGIN_DIR := $(TASK_ROOT)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(TASK_ROOT)/signatures/$(TASK_NETWORK)
RPC_URL := $(L1_RPC_URL)

SCRIPT_NAME := script/common/ownership/TransferSystemConfigOwnership.s.sol:TransferSystemConfigOwnership
CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
SC_SENDER = $(shell $(MISE_EXEC) cast call $(BASE_SECURITY_COUNCIL) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)
TRANSFER_OWNERSHIP_ENV = PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) SYSTEM_CONFIG=$(SYSTEM_CONFIG)

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
