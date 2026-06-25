include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: unpause-portal
unpause-portal:
	forge script --rpc-url $(L1_RPC_URL) RunUnpausePortal --sender $(SENDER) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --sig "run(address)" $(INCIDENT_MULTISIG)
