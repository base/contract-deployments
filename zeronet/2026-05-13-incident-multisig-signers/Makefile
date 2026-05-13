include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpdateSigners

.PHONY: deps
deps: new-forge-deps

.PHONY: new-forge-deps
new-forge-deps:
	forge install --no-git safe-global/safe-smart-account@186a21a74b327f17fc41217a927dea7064f74604

.PHONY: gen-validation
gen-validation: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)

.PHONY: gen-validation-secondary
gen-validation-secondary: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer-safe-b.json,OWNER_SAFE=$(SECONDARY_SAFE))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-secondary
execute-secondary:
	OWNER_SAFE=$(SECONDARY_SAFE) $(call MULTISIG_EXECUTE,$(SIGNATURES))
