include ../../Makefile
include ../.env
include .env

SCRIPT = UpdateSigners

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
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
	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT) --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast -vvvv
