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

SCRIPT_NAME = UpdateGasParams

RPC_URL = $(L1_RPC_URL)

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: gen-validation-rollback
gen-validation-rollback: checkout-signer-tool run-script-rollback

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: run-script-rollback
run-script-rollback:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'FROM_GAS_LIMIT=$(TO_GAS_LIMIT) \
	TO_GAS_LIMIT=$(FROM_GAS_LIMIT) FROM_ELASTICITY=$(TO_ELASTICITY) TO_ELASTICITY=$(FROM_ELASTICITY) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer-rollback.json;

.PHONY: execute
execute:
	FROM_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	TO_GAS_LIMIT=$(TO_GAS_LIMIT) \
	FROM_ELASTICITY=$(FROM_ELASTICITY) \
	TO_ELASTICITY=$(TO_ELASTICITY) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: execute-rollback
execute-rollback:
	FROM_GAS_LIMIT=$(TO_GAS_LIMIT) \
	TO_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	FROM_ELASTICITY=$(TO_ELASTICITY) \
	TO_ELASTICITY=$(FROM_ELASTICITY) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
