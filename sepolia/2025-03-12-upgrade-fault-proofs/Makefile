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

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address)" $(SAFE_A)

.PHONY: sign-b
sign-b:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address)" $(SAFE_B)

# This step is run once per "child" safe, and can be run by anyone (doesn't have to be a signer)
.PHONY: approve
approve:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address,bytes)" $(SAFE_A) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: approve-b
approve-b:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address,bytes)" $(SAFE_B) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

# This step is run once after all children safes have approved and can be run by anyone (doesn't have to be a signer)
.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
