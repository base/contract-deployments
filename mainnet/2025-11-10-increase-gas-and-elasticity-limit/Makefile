include ../../Makefile
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

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute-upgrade
execute-upgrade:
	FROM_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	TO_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	forge script --rpc-url $(L1_RPC_URL) lib/base-contracts/script/deploy/l1/SetGasLimit.sol \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: execute
execute:
	FROM_GAS_LIMIT=$(FROM_GAS_LIMIT) \
	TO_GAS_LIMIT=$(TO_GAS_LIMIT) \
	FROM_ELASTICITY=$(FROM_ELASTICITY) \
	TO_ELASTICITY=$(TO_ELASTICITY) \
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

.PHONY: sign-rollback
sign-rollback:
	FROM_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	TO_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	SAFE_NONCE=$(shell expr $$(cast call $(SYSTEM_CONFIG_OWNER) "nonce()" --rpc-url $(L1_RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) lib/base-contracts/script/deploy/l1/SetGasLimit.sol \
	--sig "sign()"

.PHONY: execute-rollback
execute-rollback:
	FROM_GAS_LIMIT=$(NEW_GAS_LIMIT) \
	TO_GAS_LIMIT=$(OLD_GAS_LIMIT) \
	SAFE_NONCE=$(shell expr $$(cast call $(SYSTEM_CONFIG_OWNER) "nonce()" --rpc-url $(L1_RPC_URL) | cast to-dec) + $(ROLLBACK_NONCE_OFFSET)) \
	forge script --rpc-url $(L1_RPC_URL) lib/base-contracts/script/deploy/l1/SetGasLimit.sol \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
