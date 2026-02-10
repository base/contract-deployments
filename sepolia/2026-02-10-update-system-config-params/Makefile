include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpdateSystemConfigParamsScript

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	mkdir -p validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	NEW_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute:
	NEW_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	NEW_ELASTICITY=$(NEW_ELASTICITY) \
	NEW_DENOMINATOR=$(NEW_DENOMINATOR) \
	NEW_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
