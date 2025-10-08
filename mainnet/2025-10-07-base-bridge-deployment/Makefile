include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@15ce3dec1df08048a329ea67f7c34728beb49b98

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = FundScript
