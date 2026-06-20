include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1 # Sepolia using hd-path of 1
endif

# Proposer
.PHONY: execute-deploy-dispute-game
execute-deploy-dispute-game:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) DeployNewPDG --broadcast


