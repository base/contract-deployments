include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# TODO: ensure `SAFE_NONCE` matches the real `OWNER_SAFE` nonce
SAFE_NONCE=6
# TODO: ensure `sender` is a signer for `OWNER_SAFE`
SENDER=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

SCRIPT_NAME=PauseBridge

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: sign-pause
sign-pause:
	IS_PAUSED=true SAFE_NONCE=$(SAFE_NONCE) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[]" --sender $(SENDER)

.PHONY: sign-unpause
sign-unpause:
	IS_PAUSED=false SAFE_NONCE=$(SAFE_NONCE) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[]" --sender $(SENDER)

# Execute
.PHONY: execute-pause
execute-pause:
	IS_PAUSED=true forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv

.PHONY: execute-unpause
execute-unpause:
	IS_PAUSED=false forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv

.PHONY: check-status
check-status:
	cast call $(L2_BRIDGE) "paused()" --rpc-url $(L2_RPC_URL)
