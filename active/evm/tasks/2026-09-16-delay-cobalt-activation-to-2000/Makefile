include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

ifndef TASK_NETWORK
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=zeronet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
RPC_URL := $(L1_RPC_URL)

SCRIPT_NAME := tasks/2026-09-16-delay-cobalt-activation-to-2000/script/DelayCobaltActivation.s.sol:DelayCobaltActivation

CB_SENDER = $(shell $(MISE_EXEC) cast call $(INCIDENT_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

UPDATE_ENV = INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) \
	PROTOCOL_VERSIONS_PROXY=$(PROTOCOL_VERSIONS_PROXY) \
	CURRENT_COBALT_ACTIVATION_TIMESTAMP=$(CURRENT_COBALT_ACTIVATION_TIMESTAMP) \
	NEW_COBALT_ACTIVATION_TIMESTAMP=$(NEW_COBALT_ACTIVATION_TIMESTAMP)

.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(CB_SENDER),base-signer.json,$(UPDATE_ENV))

.PHONY: execute
execute:
	export $(UPDATE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))
