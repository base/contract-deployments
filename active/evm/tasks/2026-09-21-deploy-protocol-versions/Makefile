include ../../../../Makefile

ifndef TASK_NETWORK
$(error TASK_NETWORK is required, e.g. make TASK_NETWORK=mainnet $(MAKECMDGOALS))
endif

PROJECT_DIR := $(abspath ../..)

include $(REPO_ROOT)/config/$(TASK_NETWORK).env
include config/$(TASK_NETWORK)/.env

ADDRESSES_JSON := $(CURDIR)/config/$(TASK_NETWORK)/addresses.json
LEDGER_HD_PATH := "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
DEPLOYER = $(shell $(MISE_EXEC) cast wallet address --ledger --mnemonic-derivation-path $(LEDGER_HD_PATH))

TASK_DIR := tasks/2026-09-21-deploy-protocol-versions
DEPLOY_PROXY_SCRIPT := $(TASK_DIR)/script/DeployProtocolVersionsProxy.s.sol:DeployProtocolVersionsProxy
DEPLOY_IMPL_SCRIPT := $(TASK_DIR)/script/DeployProtocolVersionsImpl.s.sol:DeployProtocolVersionsImpl

PROTOCOL_VERSIONS_PROXY = $(shell jq -er '.protocolVersionsProxy' $(ADDRESSES_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_IMPL = $(shell jq -er '.protocolVersionsImpl' $(ADDRESSES_JSON) 2>/dev/null)
PROTOCOL_VERSIONS_PROXY_CTOR_ARGS = $(shell jq -er '.protocolVersionsProxyConstructorArgs' $(ADDRESSES_JSON) 2>/dev/null)

IMPL_DEPLOY_ENV = ADDRESSES_JSON=$(ADDRESSES_JSON)
PROXY_DEPLOY_ENV = ADDRESSES_JSON=$(ADDRESSES_JSON) \
	DEPLOYER=$(DEPLOYER) \
	PROXY_ADMIN_OWNER=$(PROXY_ADMIN_OWNER) \
	L1_PROXY_ADMIN=$(L1_PROXY_ADMIN) \
	PROTOCOL_VERSIONS_INCIDENT_RESPONDER=$(PROTOCOL_VERSIONS_INCIDENT_RESPONDER) \
	PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION=$(PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION) \
	PROTOCOL_VERSIONS_INITIAL_SCHEDULE=$(PROTOCOL_VERSIONS_INITIAL_SCHEDULE)

.PHONY: deps
deps: task-extra-deps

.PHONY: task-extra-deps
task-extra-deps:
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge install --no-git \
		github.com/OpenZeppelin/openzeppelin-contracts@ecd2ca2cd7cac116f7a37d0e474bbb3d7d5e1c4d

.PHONY: validate-addresses
validate-addresses:
	@jq -e '.protocolVersionsProxy and .protocolVersionsImpl and .protocolVersionsProxyConstructorArgs' "$(ADDRESSES_JSON)" >/dev/null || \
		(echo "run make TASK_NETWORK=$(TASK_NETWORK) deploy first" && exit 1)

.PHONY: validate-impl
validate-impl:
	@jq -e '.protocolVersionsImpl' "$(ADDRESSES_JSON)" >/dev/null || \
		(echo "run make TASK_NETWORK=$(TASK_NETWORK) deploy-impl first" && exit 1)

DEPLOY_BUILD = FOUNDRY_OPTIMIZER=true FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun

.PHONY: deploy
deploy: deploy-proxy

.PHONY: deploy-proxy
deploy-proxy: validate-impl
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(PROXY_DEPLOY_ENV) $(DEPLOY_BUILD) FOUNDRY_OPTIMIZER_RUNS=5000 \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_PROXY_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

.PHONY: deploy-impl
deploy-impl:
	@test -f "$(ADDRESSES_JSON)" || echo '{}' > "$(ADDRESSES_JSON)"
	cd $(PROJECT_DIR) && $(IMPL_DEPLOY_ENV) $(DEPLOY_BUILD) FOUNDRY_OPTIMIZER_RUNS=999999 \
		$(MISE_EXEC) forge script --rpc-url $(L1_RPC_URL) $(DEPLOY_IMPL_SCRIPT) \
		--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv

VERIFY_DEPS = openzeppelin-contracts solady
CONTRACTS_LIB = $(PROJECT_DIR)/lib/contracts/lib
LINK_VERIFY_DEPS = mkdir -p $(CONTRACTS_LIB); \
	trap 'rm -f $(foreach d,$(VERIFY_DEPS),$(CONTRACTS_LIB)/$(d)); rmdir $(CONTRACTS_LIB) 2>/dev/null || true' EXIT; \
	for d in $(VERIFY_DEPS); do ln -sfn ../../$$d $(CONTRACTS_LIB)/$$d; done
VERIFY_COMMON = --root $(PROJECT_DIR)/lib/contracts --compilation-profile default \
	--chain $(L1_CHAIN_ID) --compiler-version v0.8.15+commit.e14f2714 \
	--verifier custom --verifier-url "https://api.etherscan.io/v2/api?chainid=$(L1_CHAIN_ID)" \
	--verifier-api-key $(VERIFIER_API_KEY) --watch

.PHONY: verify
verify: validate-addresses
ifndef VERIFIER_API_KEY
	$(error VERIFIER_API_KEY is not set)
endif
	@set -e; $(LINK_VERIFY_DEPS); cd $(PROJECT_DIR); \
		RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun FOUNDRY_OPTIMIZER_RUNS=5000 \
			$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_PROXY) src/universal/Proxy.sol:Proxy \
			--constructor-args $(PROTOCOL_VERSIONS_PROXY_CTOR_ARGS) --num-of-optimizations 5000 $(VERIFY_COMMON); \
		RUST_LOG=off FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun FOUNDRY_OPTIMIZER_RUNS=999999 \
			$(MISE_EXEC) forge verify-contract $(PROTOCOL_VERSIONS_IMPL) src/L1/ProtocolVersions.sol:ProtocolVersions \
			--num-of-optimizations 999999 $(VERIFY_COMMON)
