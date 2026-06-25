include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = SetMinBaseFeeAndDAFootprintScript

# Calculate the DA footprint gas scalar based on the formula:
# da_footprint_gas_scalar = gas_limit / (elasticity * target_blob_count * 32,000)
# Requires GAS_LIMIT, ELASTICITY, and TARGET_BLOB_COUNT to be set.
.PHONY: da-scalar
da-scalar:
ifndef TARGET_BLOB_COUNT
	$(error TARGET_BLOB_COUNT is not set. Usage: make da-scalar GAS_LIMIT=<value> ELASTICITY=<value> TARGET_BLOB_COUNT=<value>)
endif
ifndef GAS_LIMIT
	$(error GAS_LIMIT is not set. Usage: make da-scalar GAS_LIMIT=<value> ELASTICITY=<value> TARGET_BLOB_COUNT=<value>)
endif
ifndef ELASTICITY
	$(error ELASTICITY is not set. Usage: make da-scalar GAS_LIMIT=<value> ELASTICITY=<value> TARGET_BLOB_COUNT=<value>)
endif
	@echo "$(GAS_LIMIT) / ($(ELASTICITY) * $(TARGET_BLOB_COUNT) * 32000) ="
	@echo "NEW_DA_FOOTPRINT_GAS_SCALAR=$$(( $(GAS_LIMIT) / ($(ELASTICITY) * $(TARGET_BLOB_COUNT) * 32000) ))"

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	mkdir -p validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	OLD_MIN_BASE_FEE=$(OLD_MIN_BASE_FEE) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) OLD_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute:
	NEW_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	OLD_MIN_BASE_FEE=$(OLD_MIN_BASE_FEE) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: gen-validation-rollback
gen-validation-rollback: checkout-signer-tool run-script-rollback

.PHONY: run-script-rollback
run-script-rollback:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'OLD_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	NEW_MIN_BASE_FEE=$(OLD_MIN_BASE_FEE) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) NEW_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer-rollback.json;

.PHONY: execute-rollback
execute-rollback:
	OLD_MIN_BASE_FEE=$(NEW_MIN_BASE_FEE) \
	NEW_MIN_BASE_FEE=$(OLD_MIN_BASE_FEE) \
	OLD_DA_FOOTPRINT_GAS_SCALAR=$(NEW_DA_FOOTPRINT_GAS_SCALAR) \
	NEW_DA_FOOTPRINT_GAS_SCALAR=$(OLD_DA_FOOTPRINT_GAS_SCALAR) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
