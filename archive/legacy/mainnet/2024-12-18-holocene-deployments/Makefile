include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Deploy command
##
.PHONY: deploy
deploy:
	L2_CHAIN_ID=$(L2_CHAIN_ID) forge script --rpc-url $(L1_RPC_URL) DeployHoloceneContracts --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --verify --broadcast
