include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 1
endif

SENDER=0xb2d9a52e76841279EF0372c534C539a4f68f8C0B

RPC_URL=$(L1_RPC_URL)
SCRIPT_NAME=UpdateConfig

.PHONY: deps
deps:
	forge install --no-git github.com/base/bridge@$(BRIDGE_COMMIT)

.PHONY: deploy
deploy:
	forge script DeployBridgeUpdates --rpc-url $(L2_RPC_URL) \
	--account testnet-admin --broadcast -vvvv

.PHONY: deploy-o
deploy-o:
	forge script DeployRelayerOrchestrator --rpc-url $(L2_RPC_URL) \
	--account testnet-admin --broadcast -vvvv

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer.json;

# Execute
.PHONY: execute
execute:
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(SIGNATURES) --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"  --broadcast -vvvv
