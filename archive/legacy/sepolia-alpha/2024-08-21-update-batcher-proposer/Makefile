include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: execute-update-batcher
execute-update-batcher:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) UpdateBatcherHash

.PHONY: execute-rollback-batcher
execute-rollback-batcher:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) RollbackBatcherHash

.PHONY: execute-update-proposer
execute-update-proposer:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) UpdateProposer

.PHONY: execute-rollback-proposer
execute-rollback-proposer:
	forge script --rpc-url $(L1_RPC_URL) --private-key $(PRIVATE_KEY) RollbackProposer

