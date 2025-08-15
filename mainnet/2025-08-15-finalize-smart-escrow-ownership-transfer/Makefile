include ../../Makefile
include ../.env
include .env

L2_RPC_URL=https://mainnet.optimism.io

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) InitOwnershipTransfer \
	--sig "sign(address)" $(CB_SIGNER_SAFE_ADDR)

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) InitOwnershipTransfer \
	--sig "sign(address)" $(OP_SIGNER_SAFE_ADDR)

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) InitOwnershipTransfer \
	--sig "approve(address,bytes)" $(CB_SIGNER_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) InitOwnershipTransfer \
	--sig "approve(address,bytes)" $(OP_SIGNER_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: execute
execute:
	forge script --rpc-url $(L2_RPC_URL) InitOwnershipTransfer \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
