include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign-update-gas-config
sign-update-gas-config: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpdateGasConfig \
	--sig "sign()"

.PHONY: execute
execute:
	forge script --broadcast --rpc-url $(L1_RPC_URL) UpdateGasConfig \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"


.PHONY: sign-rollback-gas-config
sign-rollback-gas-config: 
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) RollbackGasConfig \
	--sig "sign()"


.PHONY: execute-rollback
execute-rollback:
	forge script --rpc-url $(L1_RPC_URL) RollbackGasConfig \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
