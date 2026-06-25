include ../../Makefile
include ../.env
include .env

SCRIPT = OwnershipTransfer

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	go install github.com/jackchuma/state-diff@v0.0.1-rc.5

.PHONY: gen-validation
gen-validation:
	$(GOPATH)/bin/state-diff --rpc $(L2_RPC_URL) -o VALIDATION.md \
	-- forge script --rpc-url $(L2_RPC_URL) $(SCRIPT) \
	--sig "sign(address[])" [] --sender 0xf9e320f3dA12E68af219d9E2A490Dd649f6B177c

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) $(SCRIPT) --sig "sign(address[])" []

.PHONY: execute
execute:
	forge script --rpc-url $(L2_RPC_URL) \
	$(SCRIPT) --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast
