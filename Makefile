SHELL := /bin/bash

# Переменные с кэшированием date для избежания повторных вызовов
CURRENT_DATE := $(shell date +'%Y-%m-%d')
PROJECT_DIR = $(network)/$(CURRENT_DATE)-$(task)
GAS_INCREASE_DIR = $(network)/$(CURRENT_DATE)-increase-gas-limit
FAULT_PROOF_UPGRADE_DIR = $(network)/$(CURRENT_DATE)-upgrade-fault-proofs
SAFE_MANAGEMENT_DIR = $(network)/$(CURRENT_DATE)-safe-swap-owner
FUNDING_DIR = $(network)/$(CURRENT_DATE)-funding
SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR = $(network)/$(CURRENT_DATE)-pause-bridge-base
PAUSE_BRIDGE_BASE_DIR = $(network)/$(CURRENT_DATE)-pause-bridge-base

# Шаблоны
TEMPLATE_GENERIC = setup-templates/template-generic
TEMPLATE_GAS_INCREASE = setup-templates/template-gas-increase
TEMPLATE_UPGRADE_FAULT_PROOFS = setup-templates/template-upgrade-fault-proofs
TEMPLATE_SAFE_MANAGEMENT = setup-templates/template-safe-management
TEMPLATE_FUNDING = setup-templates/template-funding
TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD = setup-templates/template-set-bridge-partner-threshold
TEMPLATE_PAUSE_BRIDGE_BASE = setup-templates/template-pause-bridge-base

# Общие директории для очистки
CLEAN_DIRS = cache lib out

# Оптимизация GOPATH
ifndef GOPATH
    GOPATH := $(shell go env GOPATH)
    export GOPATH
endif

# Foundry настройки
FOUNDRY_BIN := ~/.foundry/bin
FORGE := $(FOUNDRY_BIN)/forge
FOUNDRYUP := $(FOUNDRY_BIN)/foundryup

##
# Utility Functions
##
# Функция для параллельной очистки директорий
define clean_template
	@echo "Cleaning $(1)..."
	@rm -rf $(addprefix $(1)/,$(CLEAN_DIRS))
endef

# Функция для копирования с проверкой
define copy_template
	@echo "Copying $(1) to $(2)..."
	@mkdir -p $(dir $(2))
	@cp -r $(1) $(2)
endef

# Функция для git checkout с оптимизацией
define git_shallow_clone
	@echo "Cloning $(2) at commit $(3)..."
	@rm -rf $(1)
	@mkdir -p $(1)
	@cd $(1) && \
		git init --quiet && \
		git remote add origin $(2) && \
		git fetch --depth=1 --quiet origin $(3) && \
		git reset --hard --quiet FETCH_HEAD
endef

##
# Foundry Installation
##
.PHONY: install-foundry
install-foundry:
	@if [ ! -f "$(FOUNDRYUP)" ]; then \
		echo "Installing Foundry..."; \
		curl -L https://foundry.paradigm.xyz | bash; \
	else \
		echo "Foundry already installed"; \
	fi
	@$(FOUNDRYUP) --commit $(FOUNDRY_COMMIT)

##
# Project Setup (оптимизированные версии)
##
.PHONY: setup-task
setup-task:
	$(call clean_template,$(TEMPLATE_GENERIC))
	$(call copy_template,$(TEMPLATE_GENERIC),$(PROJECT_DIR))

.PHONY: setup-gas-increase
setup-gas-increase:
	$(call clean_template,$(TEMPLATE_GAS_INCREASE))
	$(call copy_template,$(TEMPLATE_GAS_INCREASE),$(GAS_INCREASE_DIR))

.PHONY: setup-upgrade-fault-proofs
setup-upgrade-fault-proofs:
	$(call copy_template,$(TEMPLATE_UPGRADE_FAULT_PROOFS),$(FAULT_PROOF_UPGRADE_DIR))

.PHONY: setup-safe-management
setup-safe-management:
	$(call clean_template,$(TEMPLATE_SAFE_MANAGEMENT))
	$(call copy_template,$(TEMPLATE_SAFE_MANAGEMENT),$(SAFE_MANAGEMENT_DIR))

.PHONY: setup-funding
setup-funding:
	$(call clean_template,$(TEMPLATE_FUNDING))
	$(call copy_template,$(TEMPLATE_FUNDING),$(FUNDING_DIR))

.PHONY: setup-bridge-partner-threshold
setup-bridge-partner-threshold:
	$(call clean_template,$(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD))
	$(call copy_template,$(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD),$(SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR))

.PHONY: setup-bridge-pause
setup-bridge-pause:
	$(call clean_template,$(TEMPLATE_PAUSE_BRIDGE_BASE))
	$(call copy_template,$(TEMPLATE_PAUSE_BRIDGE_BASE),$(PAUSE_BRIDGE_BASE_DIR))

##
# Bulk Setup (новая функция для параллельной настройки)
##
.PHONY: setup-all
setup-all: setup-gas-increase setup-safe-management setup-funding setup-bridge-partner-threshold setup-bridge-pause
	@echo "All setups completed"

##
# Solidity Setup
##
.PHONY: deps
deps: install-eip712sign clean-lib forge-deps-parallel checkout-op-commit checkout-base-contracts-commit

.PHONY: install-eip712sign
install-eip712sign:
	@if command -v eip712sign >/dev/null 2>&1; then \
		echo "eip712sign already installed"; \
	else \
		echo "Installing eip712sign..."; \
		go install github.com/base/eip712sign@v0.0.11; \
	fi

.PHONY: clean-lib
clean-lib:
	@echo "Cleaning lib directory..."
	@rm -rf lib

# Оригинальная версия (последовательная)
.PHONY: forge-deps
forge-deps:
	@echo "Installing Forge dependencies..."
	@$(FORGE) install --no-git \
		github.com/foundry-rs/forge-std \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 \
		github.com/Vectorized/solady@5ea5d9f57ed6d24a27d00934f4a3448def931415 \
		github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9

# Оптимизированная версия (параллельная установка)
.PHONY: forge-deps-parallel
forge-deps-parallel:
	@echo "Installing Forge dependencies in parallel..."
	@$(FORGE) install --no-git github.com/foundry-rs/forge-std & \
	$(FORGE) install --no-git github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 & \
	$(FORGE) install --no-git github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 & \
	$(FORGE) install --no-git github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc & \
	$(FORGE) install --no-git github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 & \
	$(FORGE) install --no-git github.com/Vectorized/solady@5ea5d9f57ed6d24a27d00934f4a3448def931415 & \
	$(FORGE) install --no-git github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9 & \
	wait

.PHONY: checkout-op-commit
checkout-op-commit:
	@[ -n "$(OP_COMMIT)" ] || (echo "ERROR: OP_COMMIT must be set in .env" && exit 1)
	$(call git_shallow_clone,lib/optimism,https://github.com/ethereum-optimism/optimism.git,$(OP_COMMIT))

.PHONY: checkout-base-contracts-commit
checkout-base-contracts-commit:
	@[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "ERROR: BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	$(call git_shallow_clone,lib/base-contracts,https://github.com/base/contracts.git,$(BASE_CONTRACTS_COMMIT))

# Параллельный checkout обоих репозиториев
.PHONY: checkout-all
checkout-all:
	@$(MAKE) -j2 checkout-op-commit checkout-base-contracts-commit

##
# Task Signer Tool
##
SIGNER_TOOL_COMMIT := f33affd459859882b30fbda29e43abfded77903a
SIGNER_TOOL_PATH := signer-tool

.PHONY: checkout-signer-tool
checkout-signer-tool:
	@[ -n "$(SIGNER_TOOL_COMMIT)" ] || (echo "ERROR: SIGNER_TOOL_COMMIT must be set" && exit 1)
	$(call git_shallow_clone,$(SIGNER_TOOL_PATH),https://github.com/base/task-signing-tool.git,$(SIGNER_TOOL_COMMIT))

.PHONY: sign
sign:
	@echo "Running signer tool..."
	@cd $(SIGNER_TOOL_PATH) && npm ci && bun dev

.PHONY: sign-task
sign-task: checkout-signer-tool sign

##
# Solidity Testing
##
.PHONY: solidity-test
solidity-test:
	@echo "Running Forge tests..."
	@$(FORGE) test --ffi -vvv

# Быстрые тесты без verbose output
.PHONY: solidity-test-quick
solidity-test-quick:
	@echo "Running quick Forge tests..."
	@$(FORGE) test --ffi

# Тесты с gas reporting
.PHONY: solidity-test-gas
solidity-test-gas:
	@echo "Running Forge tests with gas reporting..."
	@$(FORGE) test --ffi --gas-report

# Параллельные тесты (если поддерживается)
.PHONY: solidity-test-parallel
solidity-test-parallel:
	@echo "Running parallel Forge tests..."
	@$(FORGE) test --ffi -vvv --mt

##
# Utility Targets
##
.PHONY: clean-all
clean-all: clean-lib
	@echo "Cleaning all build artifacts..."
	@find . -type d -name "cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "out" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf $(SIGNER_TOOL_PATH)

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  install-foundry              - Install Foundry toolchain"
	@echo "  setup-task                   - Setup generic task"
	@echo "  setup-gas-increase          - Setup gas increase task"
	@echo "  setup-upgrade-fault-proofs  - Setup fault proofs upgrade"
	@echo "  setup-safe-management       - Setup safe management"
	@echo "  setup-funding               - Setup funding task"
	@echo "  setup-bridge-partner-threshold - Setup bridge partner threshold"
	@echo "  setup-bridge-pause          - Setup bridge pause"
	@echo "  setup-all                   - Run all setup tasks in parallel"
	@echo "  deps                        - Install all dependencies"
	@echo "  forge-deps-parallel         - Install Forge deps in parallel (faster)"
	@echo "  checkout-all                - Checkout all git dependencies in parallel"
	@echo "  sign-task                   - Run task signing tool"
	@echo "  solidity-test               - Run Forge tests (verbose)"
	@echo "  solidity-test-quick         - Run Forge tests (fast)"
	@echo "  solidity-test-gas           - Run tests with gas reporting"
	@echo "  clean-all                   - Clean all build artifacts"
	@echo ""
	@echo "Environment variables needed:"
	@echo "  OP_COMMIT                   - Optimism commit hash"
	@echo "  BASE_CONTRACTS_COMMIT       - Base contracts commit hash"
	@echo "  FOUNDRY_COMMIT              - Foundry commit hash"

.DEFAULT_GOAL := help
