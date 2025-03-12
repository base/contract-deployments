include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

##
# MultisigBuilder commands
# The following commands can be used for tasks that utilize the MultisigBuilder.
# Note that --ledger --hd-paths <PATH> can be replaced with --private-key $(PRIVATE_KEY)
# in any command when using a local key.
##

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF --sig "sign()"

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run(bytes)" $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
