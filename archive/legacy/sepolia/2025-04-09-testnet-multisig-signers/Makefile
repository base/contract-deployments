include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deps
deps:
	forge install --no-git safe-global/safe-smart-account@21dc82410445637820f600c7399a804ad55841d5

.PHONY: sign
sign:
	OWNER_SAFE=$(SAFE_A) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateSigners --sig "sign()"

.PHONY: sign-b
sign-b:
	OWNER_SAFE=$(SAFE_B) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateSigners --sig "sign()"

.PHONY: execute
execute:
	OWNER_SAFE=$(SAFE_A) forge script --rpc-url $(L1_RPC_URL) \
	UpdateSigners --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast -vvvv

.PHONY: execute-b
execute-b:
	OWNER_SAFE=$(SAFE_B) forge script --rpc-url $(L1_RPC_URL) \
	UpdateSigners --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast -vvvv
