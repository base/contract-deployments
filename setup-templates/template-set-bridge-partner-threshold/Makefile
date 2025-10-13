include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# TODO: ensure `sender` is a signer for `OWNER_SAFE`
.PHONY: gen-validation
gen-validation:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/signer.json \
	-- forge script --rpc-url $(L1_RPC_URL) SetThreshold \
	--sig "sign(address[])" "[$(OWNER_SAFE)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))