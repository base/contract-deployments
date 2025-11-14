include ../../Makefile
include ../.env
include .env

.PHONY: simulate
simulate:
	forge script --rpc-url $(L1_RPC_URL) TransferSystemConfigOwnership --sender $(SENDER)

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) TransferSystemConfigOwnership --account sepolia-alpha-admin --broadcast -vvvv