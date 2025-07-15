include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

# Overwriting this from top level makefile to change the branch
.PHONY: checkout-op-commit
checkout-op-commit:
	rm -rf lib/optimism
	mkdir -p lib/optimism
	cd lib/optimism; \
	git init; \
	git remote add origin $(OPTIMISM_REPO); \
	git fetch --depth=1 origin tag $(OPTIMISM_VERSION) --no-tags; \
	git checkout $(OPTIMISM_VERSION); \
	git apply ../../$(OPTIMISM_CONTRACT_PATCH)


.PHONY: deploy
deploy:
	forge script --rpc-url $(L1_RPC_URL) DeploySystemConfig --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --verify --broadcast

.PHONY: sign-cb
sign-cb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfig \
	--sig "sign(address)" $(CB_MULTISIG)

.PHONY: sign-op
sign-op:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfig \
	--sig "sign(address)" $(OP_MULTISIG)

.PHONY: approve-cb
approve-cb:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfig \
	--sig "approve(address,bytes)" $(CB_MULTISIG) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: approve-op
approve-op:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfig \
	--sig "approve(address,bytes)" $(OP_MULTISIG) $(SIGNATURES) \
	--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast

.PHONY: run-upgrade
run-upgrade:
	forge script --rpc-url $(L1_RPC_URL) UpgradeSystemConfig \
	--sig "run()" --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --broadcast
