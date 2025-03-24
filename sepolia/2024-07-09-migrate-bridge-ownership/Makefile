include ../../Makefile
include ../.env
include .env

##
# Foundry commands
##
.PHONY: verify
verify:
	forge script --rpc-url $(SEPOLIA_RPC_URL) VerifyContractState
