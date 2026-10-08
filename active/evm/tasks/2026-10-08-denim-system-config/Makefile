include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

# Denim rolls out across several networks from this one task directory, so the network is never
# defaulted. Select it on every command line:
#   make TASK_NETWORK=zeronet gen-validation-cb
ifndef TASK_NETWORK
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)

TASK_DIR := tasks/2026-10-08-denim-system-config
SCRIPT_NAME := $(TASK_DIR)/script/UpdateDenimGasParams.s.sol:UpdateDenimGasParams

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

GAS_ENV = CB_MULTISIG=$(CB_MULTISIG) \
	SYSTEM_CONFIG=$(SYSTEM_CONFIG) \
	DENIM_ACTIVATION_TIMESTAMP=$(DENIM_ACTIVATION_TIMESTAMP) \
	OLD_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	OLD_EIP1559_DENOMINATOR=$(OLD_EIP1559_DENOMINATOR) \
	NEW_EIP1559_DENOMINATOR=$(NEW_EIP1559_DENOMINATOR)

##
# Validation file
##
# SystemConfig is owned by the Base multisig alone, so it is the executing Safe and there are no
# nested Safes to approve.
.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(CB_SENDER),base-signer.json,$(GAS_ENV))

##
# Execute
##
.PHONY: execute
execute:
	export $(GAS_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))
