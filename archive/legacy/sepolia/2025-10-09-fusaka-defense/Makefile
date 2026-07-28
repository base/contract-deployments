include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--account testnet-admin --broadcast -vvvv

# OWNER_SAFE/
# ├── CB_SIGNER_SAFE_ADDR/
# │   ├── CB_NESTED_SAFE_ADDR/
# │   │   └── Signers
# │   └── CB_SC_SAFE_ADDR/
# │       └── Signers
# └── OP_SIGNER_SAFE_ADDR/
#     └── Signers

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = UpgradeDGF

# Validation files
.PHONY: gen-validation-op
gen-validation-op:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/OP_VALIDATION.json \
	-- forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

.PHONY: gen-validation-base-nested
gen-validation-base-nested:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/BASE_NESTED_VALIDATION.json \
	-- forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[$(CB_NESTED_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

.PHONY: gen-validation-base-sc
gen-validation-base-sc:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/BASE_SC_VALIDATION.json \
	-- forge script --rpc-url $(L1_RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[$(CB_SC_SAFE_ADDR), $(CB_SIGNER_SAFE_ADDR)]" \
	--sender 0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

# CB
.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-cb-sc
approve-cb-sc:
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

# OP
.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-coordinator
approve-coordinator:
	$(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),0x)

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
