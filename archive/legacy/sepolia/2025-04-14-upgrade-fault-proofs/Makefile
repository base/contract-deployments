include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--account testnet-admin --broadcast -vvvv

.PHONY: sign-b
sign-b:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address)" $(SAFE_B)

.PHONY: approve-b
approve-b:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address,bytes)" $(SAFE_B) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address,address)" $(SAFE_A) $(COORDINATOR_SAFE_ADDR)

.PHONY: sign-nested-b
sign-nested-b:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address,address)" $(SAFE_B) $(COORDINATOR_SAFE_ADDR)

.PHONY: approve
approve:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(SAFE_A) $(COORDINATOR_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-nested-b
approve-nested-b:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfSignerSafe(address,address,bytes)" $(SAFE_B) $(COORDINATOR_SAFE_ADDR) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-coordinator
approve-coordinator:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approveOnBehalfOfIntermediateSafe(address)" $(COORDINATOR_SAFE_ADDR) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv
