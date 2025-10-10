include ../.env
include .env

include ../../Makefile

# Override the parent Makefile's mcm-proposal command
.PHONY: mcm-proposal
mcm-proposal:
	mcmctl proposal create-update-signers \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT) \
		--new-signers $(MCM_NEW_SIGNERS) \
		--signer-groups $(MCM_SIGNER_GROUPS) \
		--group-quorums $(MCM_GROUP_QUORUMS) \
		--group-parents $(MCM_GROUP_PARENTS) \
		--clear-root $(if $(filter true,$(MCM_CLEAR_ROOT)),--clear-root)
