include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deps
deps:
	forge install --no-git safe-global/safe-smart-account@21dc82410445637820f600c7399a804ad55841d5

.PHONY: dryrun
dryrun:
	forge script --rpc-url $(L1_RPC_URL) DeployNestedOwnership --account testnet-admin -vvvv

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployNestedOwnership --account testnet-admin --broadcast -vvvv
