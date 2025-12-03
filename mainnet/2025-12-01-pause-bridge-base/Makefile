include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

SAFE_NONCE=95
SENDER=0x1841CB3C2ce6870D0417844C817849da64E6e937

SCRIPT_NAME=PauseBridge

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'IS_PAUSED=true forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

.PHONY: sign-pause
sign-pause:
	@for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing with nonce $$nonce"; \
		IS_PAUSED=true SAFE_NONCE=$$nonce $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
		--sig "sign(address[])" "[]" --sender $(SENDER); \
	done

.PHONY: sign-unpause
sign-unpause:
	@for i in $$(seq 0 19); do \
		nonce=$$(($(SAFE_NONCE) + $$i)); \
		echo "Signing with nonce $$nonce"; \
		IS_PAUSED=false SAFE_NONCE=$$nonce $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
		--sig "sign(address[])" "[]" --sender $(SENDER); \
	done
