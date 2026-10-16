include ../../../../Makefile
include $(REPO_ROOT)/Multisig.mk

# Test task for the signing tool on the `test/e2e` branch. Select the network on every command line:
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

TASK_DIR := tasks/2026-10-17-e2e-bump-safe-nonce
SCRIPT_NAME := $(TASK_DIR)/script/BumpSafeNonce.s.sol:BumpSafeNonce

CB_SENDER = $(shell $(MISE_EXEC) cast call $(CB_MULTISIG) "getOwners()(address[])" --rpc-url $(L1_RPC_URL) | tr -d '[]' | cut -d',' -f1)

NONCE_ENV = CB_MULTISIG=$(CB_MULTISIG)

##
# Validation file
##
# The Base multisig is the executing Safe, so there are no nested Safes to approve. Test networks
# skip task origin validation. Regenerate after every Base multisig transaction: the nonce is part
# of the signed hash.
.PHONY: gen-validation-cb
gen-validation-cb: deps-signer-tool
	@test -n "$(CB_SENDER)" || { echo "Could not read CB_MULTISIG owners from $(L1_RPC_URL)" >&2; exit 1; }
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(CB_SENDER),base-signer.json,$(NONCE_ENV))
	@f=$(VALIDATIONS_DIR)/base-signer.json; \
	jq 'del(.taskOriginConfig) | . + {skipTaskOriginValidation: true}' $$f > $$f.tmp && mv $$f.tmp $$f

##
# Execute
##
# Signing is the test. Execute only to exercise the execution path: it bumps the Base multisig nonce,
# which invalidates signatures for any other pending task on this Safe.
.PHONY: execute
execute:
	export $(NONCE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))
