include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deploy-test
deploy-test:
	forge script --rpc-url $(L1_RPC_URL) DeployTestProxy \
	--sig "run(address, address)" $(DEPLOYER) $(NESTED_L1_SAFE_ADDR) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --slow --broadcast

##
# Commands for signers to run to test the nested safe
##

.PHONY: sign-op
sign-op: deps
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) TestL1NestedSafe \
	--sig "sign(address)" $(OP_SAFE_ADDR)


.PHONY: sign-cb
sign-cb: deps
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --via-ir --rpc-url $(L1_RPC_URL) TestL1NestedSafe \
	--sig "sign(address)" $(CB_SAFE_ADDR)

##
# Commands for faciliators to run to test the nested safe
##

.PHONY: run
run: deps approve-op approve-cb execute

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) TestL1NestedSafe \
	--sig "approve(address,bytes)" $(OP_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) TestL1NestedSafe \
	--sig "approve(address,bytes)" $(CB_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

execute:
	forge script --rpc-url $(L1_RPC_URL) TestL1NestedSafe \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
