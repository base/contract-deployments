include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@15ce3dec1df08048a329ea67f7c34728beb49b98

.PHONY: deploy
deploy:
	forge script DeployBridge --rpc-url $(L2_RPC_URL) \
	--sender $(shell cast wallet address --ledger --hd-path "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0") \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
