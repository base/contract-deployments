include ../../Makefile
include ../.env
include .env

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
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(CB_SIGNER_SAFE),$(COORDINATOR_SAFE_ADDR)]

.PHONY: sign-sc
sign-sc:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(SECURITY_COUNCIL_SAFE),$(COORDINATOR_SAFE_ADDR)]

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(CB_SIGNER_SAFE),$(COORDINATOR_SAFE_ADDR)] $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-sc
approve-sc:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(SECURITY_COUNCIL_SAFE),$(COORDINATOR_SAFE_ADDR)] $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: approve-coordinator
approve-coordinator:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "approve(address[],bytes)" [$(COORDINATOR_SAFE_ADDR)] 0x \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: execute
execute:
	forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "run(bytes)" 0x --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast -vvvv

.PHONY: gen-validation-op
gen-validation-op:
	if [ ! -d validations ]; then mkdir validations; fi
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/OP.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(OP_SIGNER_SAFE_ADDR)] --sender 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252

.PHONY: gen-validation-cb
gen-validation-cb:
	if [ ! -d validations ]; then mkdir validations; fi
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/cb_test.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(CB_SIGNER_SAFE),$(COORDINATOR_SAFE_ADDR)] --sender 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252

.PHONY: gen-validation-sc
gen-validation-sc:
	if [ ! -d validations ]; then mkdir validations; fi
	$(GOPATH)/bin/state-diff --rpc $(L1_RPC_URL) -o validations/sc_test.md \
	-- forge script --rpc-url $(L1_RPC_URL) UpgradeDGF \
	--sig "sign(address[])" [$(SECURITY_COUNCIL_SAFE),$(COORDINATOR_SAFE_ADDR)] --sender 0x9986ccaf9e3de0ffef82a0f7fa3a06d5afe07252
