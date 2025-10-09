include ../.env
include .env

include ../../Makefile

.PHONY: ixs
ixs:
	go run main.go \
		--ixs-output $(MCM_IXS_OUTPUT) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)
