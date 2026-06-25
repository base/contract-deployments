include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

# Batcher
.PHONY: sign-update-batcher
sign-update-batcher: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateBatcherHash \
	--sig "sign()"

.PHONY: execute-update-batcher
execute-update-batcher:
	forge script --rpc-url $(L1_RPC_URL) UpdateBatcherHash \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: sign-rollback-batcher
sign-rollback-batcher: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) RollbackBatcherHash \
	--sig "sign()"

.PHONY: execute-rollback-batcher
execute-rollback-batcher:
	forge script --rpc-url $(L1_RPC_URL) RollbackBatcherHash \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
