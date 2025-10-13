include ../.env
include .env

include ../../Makefile

# Override the parent Makefile's mcm-proposal command
.PHONY: mcm-proposal
mcm-proposal:
	mcmctl proposal bridge set-partner-oracle-config \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--bridge-program-id $(BRIDGE_PROGRAM_ID) \
		--bridge $(BRIDGE_ACCOUNT) \
		--guardian $(GUARDIAN) \
		--required-threshold $(REQUIRED_THRESHOLD) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT)
