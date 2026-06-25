include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

##
# Foundry commands
##
.PHONY: deploy-challenger
deploy-challenger:
	forge script -vvvv --rpc-url $(L1_RPC_URL) DeployChallenger \
	--sig "run(address,address,address,address)" $(DEPLOYER) $(OP_SAFE) $(CB_SAFE) $(L2_OUTPUT_ORACLE_PROXY)

##
# Upgrade L2OutputOracle to use the new Challenger 1 of 2 multisig
##

.PHONY: upgrade-l2oo
upgrade-l2oo: deps
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeL2OutputOracle --sig "sign()"

.PHONY: upgrade-l2oo-run
upgrade-l2oo-run: deps
	forge script --rpc-url $(L1_RPC_URL) \
	UpgradeL2OutputOracle --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) \
	--broadcast

##
# Testing commands for OP
##

.PHONY: test-challenger
test-challenger:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --via-ir --rpc-url $(L1_RPC_URL) DeleteL2OutputsOP --sig "sign()"

.PHONY: test-challenger-run
test-challenger-run:
	forge script --via-ir --rpc-url $(L1_RPC_URL) \
	DeleteL2OutputsOP --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sender $(SENDER) \
	--broadcast

##
# Testing commands for CB
##

.PHONY: test-challenger-cb
test-challenger-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --via-ir --rpc-url $(L1_RPC_URL) DeleteL2OutputsCB --sig "sign()"

.PHONY: test-challenger-cb-run
test-challenger-cb-run:
	forge script --via-ir --rpc-url $(L1_RPC_URL) \
	DeleteL2OutputsCB --sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
	--broadcast
