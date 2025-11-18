include ../../Makefile
include ../.env
include .env

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
	SwapOwner --sig "sign()" --sender $(SENDER)' --ledger-id 0 --out ../validations/test.json;
