include ../../Makefile
include ../.env
include .env

# DRY RUN OVERRIDES
LEDGER_ACCOUNT = 1
L1_RPC_URL=https://base-sepolia.cbhq.net
# END OF OVERRIDES

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeployDisputeGames \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(OP_SIGNER_SAFE_ADDR)]

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(OP_SIGNER_SAFE_ADDR)] $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(SAFE_A),$(COORDINATOR_SAFE_ADDR)]

.PHONY: sign-kjf
sign-kjf:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(SAFE_B),$(COORDINATOR_SAFE_ADDR)]

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(SAFE_A),$(COORDINATOR_SAFE_ADDR)] $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-kjf
approve-kjf:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(SAFE_B),$(COORDINATOR_SAFE_ADDR)] $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-coordinator
approve-coordinator:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(COORDINATOR_SAFE_ADDR)] 0x \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
