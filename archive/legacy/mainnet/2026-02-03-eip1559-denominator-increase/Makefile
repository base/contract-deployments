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
SCRIPT_NAME = IncreaseEip1559DenominatorScript

# Validate required configuration before execution
.PHONY: validate-config
validate-config:
	@test -n "$(OP_COMMIT)" -a "$(OP_COMMIT)" != "TODO" || (echo "OP_COMMIT required" && exit 1)
	@test -n "$(BASE_CONTRACTS_COMMIT)" -a "$(BASE_CONTRACTS_COMMIT)" != "TODO" || (echo "BASE_CONTRACTS_COMMIT required" && exit 1)
	@test -n "$(OWNER_SAFE)" || (echo "OWNER_SAFE required" && exit 1)
	@test -n "$(SYSTEM_CONFIG)" || (echo "SYSTEM_CONFIG required" && exit 1)
	@test -n "$(SENDER)" || (echo "SENDER required" && exit 1)
	@test -n "$(FROM_DENOMINATOR)" -a "$(FROM_DENOMINATOR)" != "TODO" || (echo "FROM_DENOMINATOR required" && exit 1)
	@test -n "$(TO_DENOMINATOR)" -a "$(TO_DENOMINATOR)" != "TODO" || (echo "TO_DENOMINATOR required" && exit 1)
	@echo "Configuration validated successfully"

.PHONY: gen-validation
gen-validation: validate-config checkout-signer-tool run-script

.PHONY: run-script
run-script:
	mkdir -p validations; \
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'NEW_DENOMINATOR=$(TO_DENOMINATOR) \
	OLD_DENOMINATOR=$(FROM_DENOMINATOR) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute: validate-config
	NEW_DENOMINATOR=$(TO_DENOMINATOR) \
	OLD_DENOMINATOR=$(FROM_DENOMINATOR) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: gen-validation-rollback
gen-validation-rollback: validate-config checkout-signer-tool run-script-rollback

.PHONY: run-script-rollback
run-script-rollback:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'OLD_DENOMINATOR=$(TO_DENOMINATOR) \
	NEW_DENOMINATOR=$(FROM_DENOMINATOR) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer-rollback.json;

.PHONY: execute-rollback
execute-rollback: validate-config
	OLD_DENOMINATOR=$(TO_DENOMINATOR) \
	NEW_DENOMINATOR=$(FROM_DENOMINATOR) \
	SAFE_NONCE=$(shell expr $$(cast call $(OWNER_SAFE) "nonce()" --rpc-url $(RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
