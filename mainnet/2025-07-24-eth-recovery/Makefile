include ../../Makefile
include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

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

# ========== RECOVERY EXECUTION COMMANDS ==========

.PHONY: execute-arbitrum-recovery
execute-arbitrum-recovery:
	@if [ -z "$(ARBITRUM_RPC_URL)" ]; then \
		echo "Error: ARBITRUM_RPC_URL is required. Usage: make execute-arbitrum-recovery ARBITRUM_RPC_URL=<url>"; \
		exit 1; \
	fi
	@if [ ! -f "output/arbitrum/recovery_addresses.json" ]; then \
		echo "Error: Arbitrum recovery addresses not found. Run 'make analyze-arbitrum' first."; \
		exit 1; \
	fi
	@echo "🚀 Executing Arbitrum ETH Recovery..."
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(ARBITRUM_RPC_URL) ArbitrumExecuteRecovery \
	--sig "run()" \
	--broadcast

.PHONY: execute-base-recovery
execute-base-recovery:
	@if [ -z "$(L2_RPC_URL)" ]; then \
		echo "Error: L2_RPC_URL is required. Usage: make execute-base-recovery L2_RPC_URL=<url>"; \
		exit 1; \
	fi
	@if [ ! -f "output/base/recovery_addresses.json" ]; then \
		echo "Error: Base recovery addresses not found. Run 'make analyze-base' first."; \
		exit 1; \
	fi
	@echo "🚀 Executing Base ETH Recovery..."
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(L2_RPC_URL) BaseExecuteRecovery \
	--sig "run()" \
	--broadcast

.PHONY: execute-optimism-recovery
execute-optimism-recovery:
	@if [ -z "$(OP_RPC_URL)" ]; then \
		echo "Error: OP_RPC_URL is required. Usage: make execute-optimism-recovery OP_RPC_URL=<url>"; \
		exit 1; \
	fi
	@if [ ! -f "output/optimism/recovery_addresses.json" ]; then \
		echo "Error: Optimism recovery addresses not found. Run 'make analyze-optimism' first."; \
		exit 1; \
	fi
	@echo "🚀 Executing Optimism ETH Recovery..."
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(OP_RPC_URL) OptimismExecuteRecovery \
	--sig "run()" \
	--broadcast

# ========== DEPLOYMENTS COMMANDS ==========

.PHONY: deploy-implementation
deploy-implementation:
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is required. Usage: make deploy-implementation RPC_URL=<url>"; \
		exit 1; \
	fi
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" -- \
	forge script --rpc-url $(RPC_URL) DeployRecoveryImplementation \
	--sig "run()" \
	--broadcast

.PHONY: dry-run-deployments
dry-run-deployments:
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is required. Usage: make dry-run-deployments RPC_URL=<url>"; \
		exit 1; \
	fi
	forge script --rpc-url $(RPC_URL) DeployRecoveryProxies \
	--sig "run()" \
	--sender $(DEPLOYER)

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
	@echo "  execute-arbitrum-recovery ARBITRUM_RPC_URL=<url>  - Execute Arbitrum recovery"
	@echo "  execute-base-recovery L2_RPC_URL=<url>            - Execute Base recovery"
	@echo "  execute-optimism-recovery OP_RPC_URL=<url>        - Execute Optimism recovery"
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
	@echo "  ARBITRUM_RPC_URL  - Arbitrum One RPC endpoint"
	@echo "  OP_RPC_URL        - Optimism RPC endpoint"
	@echo "  L2_RPC_URL        - Base RPC endpoint"
