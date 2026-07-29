include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpdateSigners

VALIDATIONS_DIR = validations
PRIMARY_VALIDATION_FILE = base-signer.json
SECONDARY_VALIDATION_FILE = base-signer-safe-b.json

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deps
deps: new-forge-deps

.PHONY: new-forge-deps
new-forge-deps:
	forge install --no-git safe-global/safe-smart-account@186a21a74b327f17fc41217a927dea7064f74604

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'OWNER_SAFE=$(PRIMARY_SAFE) forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' \
	--out ../$(VALIDATIONS_DIR)/$(PRIMARY_VALIDATION_FILE);

.PHONY: gen-validation-secondary
gen-validation-secondary: checkout-signer-tool run-script-secondary

.PHONY: run-script-secondary
run-script-secondary:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'OWNER_SAFE=$(SECONDARY_SAFE) forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' \
	--out ../$(VALIDATIONS_DIR)/$(SECONDARY_VALIDATION_FILE);

.PHONY: execute
execute:
	OWNER_SAFE=$(PRIMARY_SAFE) $(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-secondary
execute-secondary:
	OWNER_SAFE=$(SECONDARY_SAFE) $(call MULTISIG_EXECUTE,$(SIGNATURES))
