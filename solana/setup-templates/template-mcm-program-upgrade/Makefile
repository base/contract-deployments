include ../.env
include .env

include ../../Makefile

.PHONY: write-buffer
write-buffer:
	solana program write-buffer $(PROGRAM_BINARY) \
		--url $(SOL_RPC_URL)

.PHONY: transfer-buffer
transfer-buffer:
	solana program set-buffer-authority $(BUFFER) \
		--new-buffer-authority $(MCM_AUTHORITY) \
		--url $(SOL_RPC_URL)

.PHONY: ixs
ixs:
	go run main.go \
		--ixs-output $(MCM_IXS_OUTPUT) \
		--rpc-url $(SOL_RPC_URL) \
		--program $(PROGRAM) \
		--buffer $(BUFFER) \
		--spill $(SPILL)
