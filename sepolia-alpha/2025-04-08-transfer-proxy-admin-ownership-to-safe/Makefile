include ../../Makefile
include ../.env
include .env

.PHONY: simulate
simulate:
	forge script --rpc-url $(L1_RPC_URL) TransferOwnership --sender $(SENDER)

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) TransferOwnership --sender $(SENDER) --broadcast -vvvv
