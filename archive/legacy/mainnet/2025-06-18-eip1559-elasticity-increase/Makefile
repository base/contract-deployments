include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) IncreaseEip1559ElasticityAndIncreaseGasLimitScript \
	--sig "sign(address[])" "[]"

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) IncreaseEip1559ElasticityAndIncreaseGasLimitScript \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv