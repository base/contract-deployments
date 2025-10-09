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
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) FundScript \
	--sig "sign(address[])" "[]" --sender 0x644e3DedB0e4F83Bfcf8F9992964d240224B74dc

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
