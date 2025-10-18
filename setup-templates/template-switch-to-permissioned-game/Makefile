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
