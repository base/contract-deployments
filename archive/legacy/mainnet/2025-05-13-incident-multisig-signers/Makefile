include ../../Makefile
include ../.env
include .env

SCRIPT = UpdateSigners

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps: new-go-deps new-forge-deps

.PHONY: new-go-deps
new-go-deps:
	go install github.com/jackchuma/state-diff@v0.0.1

.PHONY: new-forge-deps
new-forge-deps:
	forge install --no-git safe-global/safe-smart-account@186a21a74b327f17fc41217a927dea7064f74604

.PHONY: gen-validation
gen-validation:
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o VALIDATION.md \
	-- forge script --rpc-url $(L1_RPC_URL) $(SCRIPT) \
	--sig "sign(address[])" [] --sender 0x24c3AE1AeDB8142D32BB6d3B988f5910F272D53b

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) $(SCRIPT) --sig "sign(address[])" []

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT) --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast -vvvv
