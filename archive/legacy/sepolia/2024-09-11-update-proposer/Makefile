include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1# Sepolia using hd-path of 1
endif

.PHONY: sign-update-proposer
sign-update-proposer: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateProposer \
	--sig "sign()"

.PHONY: execute-update-proposer
execute-update-proposer:
	forge script --rpc-url $(L1_RPC_URL) UpdateProposer \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: sign-rollback-proposer
sign-rollback-proposer: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) RollbackProposer \
	--sig "sign()"

.PHONY: execute-rollback-proposer
execute-rollback-proposer:
	forge script --rpc-url $(L1_RPC_URL) RollbackProposer \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
