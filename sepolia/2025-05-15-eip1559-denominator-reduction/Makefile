include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

MOCK_OP_NESTED=0x6AF0674791925f767060Dd52f7fB20984E8639d8
CB_COORDINATOR=0x646132A1667ca7aD00d36616AFBA1A28116C770A
CB_NESTED=0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f

.PHONY: sign-mock-op-nested
sign-mock-op-nested:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(MOCK_OP_NESTED)]"

.PHONY: sign-cb-nested-coordinator
sign-cb-nested-coordinator:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(CB_NESTED), $(CB_COORDINATOR)]"

.PHONY: sign-mock-op-nested-coordinator
sign-mock-op-nested-coordinator:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "sign(address[])" "[$(MOCK_OP_NESTED), $(CB_COORDINATOR)]"

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) ReduceEip1559DenominatorScript \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
