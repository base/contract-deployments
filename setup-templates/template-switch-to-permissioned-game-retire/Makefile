include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = SwitchToPermissionedGame

# OP
.PHONY: sign-op
sign-op:
	$(call MULTISIG_SIGN,$(OP_SECURITY_COUNCIL_SAFE))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SECURITY_COUNCIL_SAFE),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)

# Base -- used for simulating the transcations as op-signers by base engineers
.PHONY: sign-base-mainnet
sign-base-mainnet:
	$(call MULTISIG_SIGN,$(OP_SECURITY_COUNCIL_SAFE)) --sender 0x1822b35B09f5ce1C78ecbC06AC0A4e17885b925e

.PHONY: sign-base-sepolia
sign-base-sepolia:
	$(call MULTISIG_SIGN,$(OP_SECURITY_COUNCIL_SAFE)) --sender 0x1084092Ac2f04c866806CF3d4a385Afa4F6A6C97
