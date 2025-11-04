include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) SetJovianParametersScript \
	--sig "sign(address[])" "[$(OWNER_SAFE)]"

.PHONY: approve
approve:
	forge script --rpc-url $(L1_RPC_URL) SetJovianParametersScript \
	--sig "approve(address[],bytes)" "[$(OWNER_SAFE)]" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) SetJovianParametersScript \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv