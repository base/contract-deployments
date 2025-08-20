include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv


# Mainnet Commands

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

# CB
.PHONY: sign-cb
sign-cb:
	$(call MULTISIG_SIGN,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_NESTED_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: sign-cb-sc
sign-cb-sc:
	$(call MULTISIG_SIGN,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR))

.PHONY: approve-cb-sc
approve-cb-sc:
	$(call MULTISIG_APPROVE,$(CB_SC_SAFE_ADDR) $(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

# OP
.PHONY: sign-op
sign-op:
	$(call MULTISIG_SIGN,$(OP_SIGNER_SAFE_ADDR))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
