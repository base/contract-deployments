include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

SCRIPT_NAME = DeploySafe

RPC_URL = $(L1_RPC_URL)

.PHONY: safe-deps
safe-deps:
	forge install --no-git safe-global/safe-smart-account@21dc82410445637820f600c7399a804ad55841d5

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
