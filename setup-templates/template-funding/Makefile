include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif


# OWNER_SAFE/
# └── Signers


RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = FundScript

.PHONY: sign
sign:
	$(call MULTISIG_SIGN,)

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
