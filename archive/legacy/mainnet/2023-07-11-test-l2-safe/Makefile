include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Foundry commands
##
.PHONY: deploy-test
deploy-test:
	forge script --rpc-url $(L2_RPC_URL) DeployTestProxy \
	--sig "run(address, address)" $(DEPLOYER) $(L2_SAFE) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

##
# MultisigBuilder commands
##

.PHONY: sign
sign:
	cd lib/base-contracts && \
	go run ./cmd/sign --workdir ../.. --ledger -- forge script --via-ir --rpc-url $(L2_RPC_URL) TestL2Safe --sig "sign()"

.PHONY: run
run:
	forge script --via-ir --rpc-url $(L2_RPC_URL) \
	TestL2Safe --sig "run(bytes)" $(SIGNATURES) --sender $(SENDER) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
