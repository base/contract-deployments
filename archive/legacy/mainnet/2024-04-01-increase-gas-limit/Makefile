include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign-update-gas-limit
sign-update-gas-limit: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateGaslimit \
	--sig "sign()"

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpdateGaslimit \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast


.PHONY: sign-rollback-gas-limit
sign-rollback-gas-limit: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) RollbackGasLimit \
	--sig "sign()"


.PHONY: execute-rollback
execute-rollback:
	forge script --rpc-url $(L1_RPC_URL) RollbackGasLimit \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
