include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git safe-global/safe-smart-account@21dc82410445637820f600c7399a804ad55841d5

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeploySafes --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateSigners --sig "sign()"

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpdateSigners \
	--sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
