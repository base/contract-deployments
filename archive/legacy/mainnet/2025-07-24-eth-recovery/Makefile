include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git github.com/OffchainLabs/nitro-contracts@v3.1.1

# ========== DEPLOYMENTS COMMANDS ==========

.PHONY: deploy-implementation
deploy-implementation:
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is required. Usage: make deploy-implementation RPC_URL=<url>"; \
		exit 1; \
	fi
	forge script --rpc-url $(RPC_URL) DeployRecoveryImplementation \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run()" --broadcast

.PHONY: dry-run-deployments
dry-run-deployments:
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is required. Usage: make dry-run-deployments RPC_URL=<url>"; \
		exit 1; \
	fi
	forge script --rpc-url $(RPC_URL) DeployRecoveryProxies --sig "run()" --sender $(DEPLOYER)

###################################################################################################
#                                  Execute Recovery Commands
###################################################################################################

ARBITRUM_BATCHES = 6 # batch size is 100 and there are 593 total addresses
OPTIMISM_BATCHES = 4 # batch size is 100 and there are 349 total addresses
BASE_BATCHES = 15 # batch size is 100 and there are 1407 total addresses
BASE = base
OPTIMISM = optimism
STARTING_SAFE_NONCE=65

.PHONY: sign-arb
sign-arb:
	for i in $$(seq 0 $$(( $(ARBITRUM_BATCHES) - 1 ))); do \
		SAFE_NONCE=$$(( $(STARTING_SAFE_NONCE) + $$i )) ADDRESS_INDEX=$$i $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
			forge script --rpc-url $(L1_RPC_URL) ArbitrumExecuteRecovery --sig "sign(address[])" [] || exit 1; \
		echo "Batch: $$((i + 1)) / $(ARBITRUM_BATCHES) completed\n"; \
	done

.PHONY: execute-arb
execute-arb:
	forge script --rpc-url $(L1_RPC_URL) ArbitrumExecuteRecovery --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
		--sig "run(bytes)" $(SIGNATURES) --broadcast


.PHONY: sign-base
sign-base:
	for i in $$(seq 0 $$(( $(BASE_BATCHES) - 1 ))); do \
		SAFE_NONCE=$$(( $(STARTING_SAFE_NONCE) + $$i )) ADDRESS_INDEX=$$i CHAIN=$(BASE) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
			forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" [] || exit 1; \
		echo "Batch: $$((i + 1)) / $(BASE_BATCHES) completed\n"; \
	done

.PHONY: execute-base
execute-base:
	CHAIN=$(BASE) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast

.PHONY: sign-op
sign-op:
	for i in $$(seq 0 $$(( $(OPTIMISM_BATCHES) - 1 ))); do \
		SAFE_NONCE=$$(( $(STARTING_SAFE_NONCE) + $$i )) ADDRESS_INDEX=$$i CHAIN=$(OPTIMISM) PORTAL=$(OPTIMISM_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
			forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" [] || exit 1; \
		echo "Batch: $$((i + 1)) / $(OPTIMISM_BATCHES) completed\n"; \
	done
	
.PHONY: execute-op
execute-op:
	CHAIN=$(OPTIMISM) PORTAL=$(OPTIMISM_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast
