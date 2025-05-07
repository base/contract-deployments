include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sim-transfer
sim-transfer:
	forge script --rpc-url $(L2_RPC_URL) OwnershipTransfer --sig "run()" --sender "${OWNER_EOA}" -vvvv

.PHONY: transfer
transfer:
	forge script --rpc-url $(L2_RPC_URL) \
	OwnershipTransfer --sig "run()" \
	--broadcast -vvvv
