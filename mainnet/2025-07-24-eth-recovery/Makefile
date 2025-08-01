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
