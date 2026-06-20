include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Commands for signers to run to test the nested safe
##

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "sign(address)" $(OP_SAFE_ADDR)

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "sign(address)" $(CB_SAFE_ADDR)

##
# Commands for faciliators to run to test the nested safe
##

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "approve(address,bytes)" $(OP_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "approve(address,bytes)" $(CB_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast

execute:
	forge script --rpc-url $(L2_RPC_URL) UpgradeToEAS \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) --broadcast
