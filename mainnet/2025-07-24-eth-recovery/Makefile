include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

.PHONY: deps
deps:
	forge install --no-git github.com/OffchainLabs/nitro-contracts@v3.1.1

# ========== ANALYSIS COMMANDS ==========

.PHONY: install-analysis-deps
install-analysis-deps:
	@echo "Installing TypeScript dependencies for analysis..."
	npm install

.PHONY: analyze-arbitrum
analyze-arbitrum:
	@echo "🔍 Analyzing Arbitrum One (Chain ID: 42161)..."
	@if [ ! -f "output/arbitrum/recovery_addresses.json" ]; then \
		echo "Running analysis for Arbitrum..."; \
		npx tsx src/analyze.ts 42161; \
	else \
		echo "✅ Arbitrum recovery addresses already exist at output/arbitrum/recovery_addresses.json"; \
	fi

.PHONY: analyze-base
analyze-base:
	@echo "🔍 Analyzing Base (Chain ID: 8453)..."
	@if [ ! -f "output/base/recovery_addresses.json" ]; then \
		echo "Running analysis for Base..."; \
		npx tsx src/analyze.ts 8453; \
	else \
		echo "✅ Base recovery addresses already exist at output/base/recovery_addresses.json"; \
	fi

.PHONY: analyze-optimism
analyze-optimism:
	@echo "🔍 Analyzing Optimism (Chain ID: 10)..."
	@if [ ! -f "output/optimism/recovery_addresses.json" ]; then \
		echo "Running analysis for Optimism..."; \
		npx tsx src/analyze.ts 10; \
	else \
		echo "✅ Optimism recovery addresses already exist at output/optimism/recovery_addresses.json"; \
	fi

.PHONY: analyze-all
analyze-all: analyze-arbitrum analyze-base analyze-optimism
	@echo "✅ All chain analyses complete!"

.PHONY: clean-analysis
clean-analysis:
	@echo "🧹 Cleaning analysis results..."
	rm -f output/arbitrum/*.json
	rm -f output/base/*.json
	rm -f output/optimism/*.json

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

BASE = base
BASE1 = base1
BASE2 = base2
BASE3 = base3
BASE4 = base4
BASE5 = base5
OPTIMISM = optimism

.PHONY: sign-arb
sign-arb:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) ArbitrumExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-arb
execute-arb:
	forge script --rpc-url $(L1_RPC_URL) ArbitrumExecuteRecovery --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" \
		--sig "run(bytes)" $(SIGNATURES) --broadcast


.PHONY: sign-base1
sign-base1:
	CHAIN=$(BASE1) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-base1
execute-base1:
	CHAIN=$(BASE1) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast

.PHONY: sign-base2
sign-base2:
	CHAIN=$(BASE2) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-base2
execute-base2:
	CHAIN=$(BASE2) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast

.PHONY: sign-base3
sign-base3:
	CHAIN=$(BASE3) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-base3
execute-base3:
	CHAIN=$(BASE3) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast

.PHONY: sign-base4
sign-base4:
	CHAIN=$(BASE4) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-base4
execute-base4:
	CHAIN=$(BASE4) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast

.PHONY: sign-base5
sign-base5:
	CHAIN=$(BASE5) PORTAL=$(BASE_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []

.PHONY: execute-base5
execute-base5:
	CHAIN=$(BASE5) PORTAL=$(BASE_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast


.PHONY: sign-op
sign-op:
	CHAIN=$(OPTIMISM) PORTAL=$(OPTIMISM_L1_PORTAL) $(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
		forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery --sig "sign(address[])" []
	
.PHONY: execute-op
execute-op:
	CHAIN=$(OPTIMISM) PORTAL=$(OPTIMISM_L1_PORTAL) forge script --rpc-url $(L1_RPC_URL) OPStackExecuteRecovery \
		--ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --sig "run(bytes)" $(SIGNATURES) --broadcast


# ========== HELP ==========

.PHONY: help
help:
	@echo "ETH Recovery Makefile Commands:"
	@echo ""
	@echo "Analysis Commands:"
	@echo "  install-analysis-deps     - Install TypeScript dependencies"
	@echo "  analyze-arbitrum         - Analyze Arbitrum addresses (Chain ID: 42161)"
	@echo "  analyze-base             - Analyze Base addresses (Chain ID: 8453)"
	@echo "  analyze-optimism         - Analyze Optimism addresses (Chain ID: 10)"
	@echo "  analyze-all              - Run analysis for all chains"
	@echo "  clean-analysis           - Remove all analysis results"
	@echo ""
	@echo "Recovery Execution Commands:"
	@echo "  execute-arbitrum-recovery L1_RPC_URL=<url>        - Execute Arbitrum recovery"
	@echo "  execute-base-recovery L2_RPC_URL=<url>            - Execute Base recovery"
	@echo "  execute-optimism-recovery L1_RPC_URL=<url>        - Execute Optimism recovery"
	@echo ""
	@echo "Dry Run Commands:"
	@echo "  dry-run-arbitrum-recovery ARBITRUM_RPC_URL=<url>  - Dry run Arbitrum recovery"
	@echo "  dry-run-base-recovery L2_RPC_URL=<url>            - Dry run Base recovery"
	@echo "  dry-run-optimism-recovery OP_RPC_URL=<url>        - Dry run Optimism recovery"
	@echo ""
	@echo "Legacy Commands:"
	@echo "  deploy-implementation RPC_URL=<url>      - Deploy recovery implementation"
	@echo "  dry-run-deployments RPC_URL=<url>        - Dry run deployments"
	@echo ""
	@echo "Environment Variables:"
	@echo "  L1_RPC_URL        - Mainnet RPC endpoint (for Arbitrum and Optimism)"
	@echo "  L2_RPC_URL        - Base RPC endpoint"
