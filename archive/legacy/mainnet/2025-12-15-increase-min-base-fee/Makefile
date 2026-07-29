include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# Gas/elasticity task executes first at nonce 98, so this task uses nonce 99.
SAFE_NONCE=99

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = IncreaseMinBaseFeeScript

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd '$(if $(SAFE_NONCE),SAFE_NONCE=$(SAFE_NONCE) )forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
