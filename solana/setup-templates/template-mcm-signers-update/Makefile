include ../.env
include .env

include ../../Makefile

.PHONY: ixs
ixs:
	go run main.go \
		--ixs-output $(MCM_IXS_OUTPUT) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		$(if $(filter true,$(MCM_CLEAR_ROOT)),--clear-root) \
		--new-signers $(MCM_NEW_SIGNERS) \
		--signer-groups $(MCM_SIGNER_GROUPS) \
		--group-quorums $(MCM_GROUP_QUORUMS) \
		--group-parents $(MCM_GROUP_PARENTS)