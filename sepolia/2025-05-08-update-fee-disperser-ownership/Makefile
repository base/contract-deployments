include ../../Makefile
include ../.env
include .env

.PHONY: sim-transfer
sim-transfer:
	forge script --rpc-url $(L2_RPC_URL) OwnershipTransfer --sig "run()" --sender "${OWNER_EOA}" -vvvv

.PHONY: transfer
transfer:
	forge script --rpc-url $(L2_RPC_URL) \
	OwnershipTransfer --sig "run()" \
	--account sepolia-fee-disperser-owner --broadcast -vvvv
