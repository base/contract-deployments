include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = FundScript
