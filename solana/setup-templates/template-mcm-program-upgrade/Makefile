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

# Override the parent Makefile's mcm-proposal command
.PHONY: mcm-proposal
mcm-proposal:
	mcmctl proposal create-upgrade \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT)
		--program $(PROGRAM) \
		--buffer $(BUFFER) \
		--spill $(SPILL)
