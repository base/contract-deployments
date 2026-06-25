include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: sign
sign:
	chmod +x ./sign.sh && ./sign.sh

.PHONY: run
run:
	forge script --via-ir --rpc-url $(L1_RPC_URL) TransferSystemConfigOwner \
	--sender $(SENDER) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--sig "run(bytes)" $(SIGNATURES) --broadcast