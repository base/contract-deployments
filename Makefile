SHELL := /bin/bash
.DEFAULT_GOAL := help

# Configuration
FOUNDRY_COMMIT ?= 3b1129b5bc43ba22a9bcf4e4323c5a9df0023140
SIGNER_TOOL_COMMIT := f33affd459859882b30fbda29e43abfded77903a
SIGNER_TOOL_PATH := signer-tool

# Кэшированная дата для избежания повторных вызовов
CURRENT_DATE := $(shell date +'%Y-%m-%d')

# Directories с оптимизированным определением
PROJECT_DIR = $(network)/$(CURRENT_DATE)-$(task)
GAS_INCREASE_DIR = $(network)/$(CURRENT_DATE)-increase-gas-limit
FAULT_PROOF_UPGRADE_DIR = $(network)/$(CURRENT_DATE)-upgrade-fault-proofs
SAFE_MANAGEMENT_DIR = $(network)/$(CURRENT_DATE)-safe-swap-owner
FUNDING_DIR = $(network)/$(CURRENT_DATE)-funding
SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR = $(network)/$(CURRENT_DATE)-pause-bridge-base
PAUSE_BRIDGE_BASE_DIR = $(network)/$(CURRENT_DATE)-pause-bridge-base

# Templates
TEMPLATE_GENERIC = setup-templates/template-generic
TEMPLATE_GAS_INCREASE = setup-templates/template-gas-increase
TEMPLATE_UPGRADE_FAULT_PROOFS = setup-templates/template-upgrade-fault-proofs
TEMPLATE_SAFE_MANAGEMENT = setup-templates/template-safe-management
TEMPLATE_FUNDING = setup-templates/template-funding
TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD = setup-templates/template-set-bridge-partner-threshold
TEMPLATE_PAUSE_BRIDGE_BASE = setup-templates/template-pause-bridge-base

# Directories to clean
CLEAN_DIRS = cache lib out

# Go configuration
ifndef GOPATH
    GOPATH := $(shell go env GOPATH)
    export GOPATH
endif

# Forge configuration
FORGE := forge
FORGE_FLAGS := --no-git

##
# Utility Functions
##
define clean_template
	@echo "Cleaning $(1)..."
	@rm -rf $(addprefix $(1)/,$(CLEAN_DIRS))
endef

define copy_template
	@echo "Copying $(1) to $(2)..."
	@mkdir -p $(dir $(2))
	@cp -r $(1) $(2)
	@echo "✓ Setup complete: $(2)"
endef

define git_shallow_clone
	@echo "Cloning $(2) at commit $(3)..."
	@rm -rf $(1)
	@mkdir -p $(1)
	@cd $(1) && \
		git init --quiet && \
		git remote add origin $(2) && \
		git fetch --depth=1 --quiet origin $(3) && \
		git reset --hard --quiet FETCH_HEAD
	@echo "✓ Cloned: $(1)"
endef

define check_env_var
	@[ -n "$($(1))" ] || (echo "ERROR: $(1) must be set in .env" && exit 1)
endef

##
# Foundry Installation
##
.PHONY: install-foundry
install-foundry:
	@if [ ! -f ~/.foundry/bin/foundryup ]; then \
		echo "Installing Foundry..."; \
		curl -L https://foundry.paradigm.xyz | bash; \
	else \
		echo "Foundry already installed"; \
	fi
	@echo "Updating Foundry to commit $(FOUNDRY_COMMIT)..."
	@~/.foundry/bin/foundryup --commit $(FOUNDRY_COMMIT)
	@echo "✓ Foundry ready"

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

# Параллельная настройка всех шаблонов
.PHONY: setup-all
setup-all:
	@echo "Setting up all templates in parallel..."
	@$(MAKE) -j5 setup-gas-increase setup-safe-management setup-funding setup-bridge-partner-threshold setup-bridge-pause
	@echo "✓ All templates setup complete"

##
# Solidity Setup
##
.PHONY: deps
deps: install-eip712sign clean-lib forge-deps-parallel checkout-all
	@echo "✓ All dependencies installed"

.PHONY: install-eip712sign
install-eip712sign:
	@if command -v eip712sign >/dev/null 2>&1; then \
		echo "eip712sign already installed"; \
	else \
		echo "Installing eip712sign..."; \
		go install github.com/base/eip712sign@v0.0.11; \
		echo "✓ eip712sign installed"; \
	fi

.PHONY: clean-lib
clean-lib:
	@echo "Cleaning lib directory..."
	@rm -rf lib
	@echo "✓ lib cleaned"

# Оригинальная последовательная версия (для совместимости)
.PHONY: forge-deps
forge-deps:
	@echo "Installing Forge dependencies (sequential)..."
	@$(FORGE) install $(FORGE_FLAGS) \
		github.com/foundry-rs/forge-std \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 \
		github.com/Vectorized/solady@5ea5d9f57ed6d24a27d00934f4a3448def931415 \
		github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9
	@echo "✓ Forge dependencies installed"

# Оптимизированная параллельная версия
.PHONY: forge-deps-parallel
forge-deps-parallel:
	@echo "Installing Forge dependencies in parallel..."
	@$(FORGE) install $(FORGE_FLAGS) github.com/foundry-rs/forge-std & \
	$(FORGE) install $(FORGE_FLAGS) github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 & \
	$(FORGE) install $(FORGE_FLAGS) github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 & \
	$(FORGE) install $(FORGE_FLAGS) github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc & \
	$(FORGE) install $(FORGE_FLAGS) github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 & \
	$(FORGE) install $(FORGE_FLAGS) github.com/Vectorized/solady@5ea5d9f57ed6d24a27d00934f4a3448def931415 & \
	$(FORGE) install $(FORGE_FLAGS) github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9 & \
	wait
	@echo "✓ Forge dependencies installed (parallel)"

.PHONY: checkout-op-commit
checkout-op-commit:
	$(call check_env_var,OP_COMMIT)
	$(call git_shallow_clone,lib/optimism,https://github.com/ethereum-optimism/optimism.git,$(OP_COMMIT))

.PHONY: checkout-base-contracts-commit
checkout-base-contracts-commit:
	$(call check_env_var,BASE_CONTRACTS_COMMIT)
	$(call git_shallow_clone,lib/base-contracts,https://github.com/base/contracts.git,$(BASE_CONTRACTS_COMMIT))

# Параллельный checkout обоих репозиториев
.PHONY: checkout-all
checkout-all:
	@echo "Checking out repositories in parallel..."
	@$(MAKE) -j2 checkout-op-commit checkout-base-contracts-commit
	@echo "✓ All repositories checked out"

##
# Task Signer Tool
##
.PHONY: checkout-signer-tool
checkout-signer-tool:
	$(call check_env_var,SIGNER_TOOL_COMMIT)
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
	@echo "Running Forge tests (verbose)..."
	@$(FORGE) test --ffi -vvv

.PHONY: solidity-test-quick
solidity-test-quick:
	@echo "Running quick Forge tests..."
	@$(FORGE) test --ffi

.PHONY: solidity-test-gas
solidity-test-gas:
	@echo "Running Forge tests with gas report..."
	@$(FORGE) test --ffi --gas-report

.PHONY: solidity-test-coverage
solidity-test-coverage:
	@echo "Running Forge tests with coverage..."
	@$(FORGE) coverage --ffi

.PHONY: solidity-test-watch
solidity-test-watch:
	@echo "Running Forge tests in watch mode..."
	@$(FORGE) test --ffi --watch

##
# Build & Compile
##
.PHONY: build
build:
	@echo "Building contracts..."
	@$(FORGE) build
	@echo "✓ Build complete"

.PHONY: build-clean
build-clean: clean-build build

.PHONY: clean-build
clean-build:
	@echo "Cleaning build artifacts..."
	@$(FORGE) clean
	@echo "✓ Build artifacts cleaned"

##
# Formatting & Linting
##
.PHONY: fmt
fmt:
	@echo "Formatting Solidity code..."
	@$(FORGE) fmt
	@echo "✓ Code formatted"

.PHONY: fmt-check
fmt-check:
	@echo "Checking Solidity formatting..."
	@$(FORGE) fmt --check

##
# Snapshots
##
.PHONY: snapshot
snapshot:
	@echo "Creating gas snapshot..."
	@$(FORGE) snapshot
	@echo "✓ Snapshot created"

.PHONY: snapshot-diff
snapshot-diff:
	@echo "Comparing gas snapshot..."
	@$(FORGE) snapshot --diff

##
# Utility Targets
##
.PHONY: clean-all
clean-all: clean-lib clean-build
	@echo "Cleaning all artifacts..."
	@rm -rf $(SIGNER_TOOL_PATH)
	@find . -type d -name "cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "out" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ All artifacts cleaned"

.PHONY: verify-env
verify-env:
	@echo "Verifying environment variables..."
	$(call check_env_var,OP_COMMIT)
	$(call check_env_var,BASE_CONTRACTS_COMMIT)
	@echo "✓ Environment variables verified"

.PHONY: list-templates
list-templates:
	@echo "Available templates:"
	@echo "  - generic:                $(TEMPLATE_GENERIC)"
	@echo "  - gas-increase:           $(TEMPLATE_GAS_INCREASE)"
	@echo "  - upgrade-fault-proofs:   $(TEMPLATE_UPGRADE_FAULT_PROOFS)"
	@echo "  - safe-management:        $(TEMPLATE_SAFE_MANAGEMENT)"
	@echo "  - funding:                $(TEMPLATE_FUNDING)"
	@echo "  - bridge-partner-threshold: $(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD)"
	@echo "  - bridge-pause:           $(TEMPLATE_PAUSE_BRIDGE_BASE)"

.PHONY: version
version:
	@echo "Configuration:"
	@echo "  Foundry commit:     $(FOUNDRY_COMMIT)"
	@echo "  Signer tool commit: $(SIGNER_TOOL_COMMIT)"
	@echo "  GOPATH:             $(GOPATH)"
	@echo "  Current date:       $(CURRENT_DATE)"

##
# CI/CD Targets
##
.PHONY: ci
ci: deps fmt-check solidity-test-quick build
	@echo "✓ CI pipeline complete"

.PHONY: ci-full
ci-full: deps fmt-check solidity-test-coverage build snapshot
	@echo "✓ Full CI pipeline complete"

##
# Help
##
.PHONY: help
help:
	@echo "Base Task Management Makefile"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup-task network=<n> task=<t>  Setup generic task"
	@echo "  setup-gas-increase network=<n>   Setup gas increase"
	@echo "  setup-upgrade-fault-proofs n=<n> Setup fault proofs upgrade"
	@echo "  setup-safe-management network=<n> Setup safe management"
	@echo "  setup-funding network=<n>        Setup funding"
	@echo "  setup-bridge-partner-threshold   Setup bridge partner threshold"
	@echo "  setup-bridge-pause network=<n>   Setup bridge pause"
	@echo "  setup-all                        Setup all templates in parallel"
	@echo ""
	@echo "Dependency targets:"
	@echo "  deps                   Install all dependencies"
	@echo "  install-foundry        Install/update Foundry"
	@echo "  install-eip712sign     Install eip712sign tool"
	@echo "  forge-deps             Install Forge deps (sequential)"
	@echo "  forge-deps-parallel    Install Forge deps (parallel, faster)"
	@echo "  checkout-all           Checkout all repos in parallel"
	@echo "  clean-lib              Remove lib directory"
	@echo ""
	@echo "Testing targets:"
	@echo "  solidity-test          Run tests (verbose)"
	@echo "  solidity-test-quick    Run tests (fast)"
	@echo "  solidity-test-gas      Run tests with gas report"
	@echo "  solidity-test-coverage Run tests with coverage"
	@echo "  solidity-test-watch    Run tests in watch mode"
	@echo ""
	@echo "Build targets:"
	@echo "  build                  Compile contracts"
	@echo "  build-clean            Clean and build"
	@echo "  clean-build            Remove build artifacts"
	@echo ""
	@echo "Quality targets:"
	@echo "  fmt                    Format Solidity code"
	@echo "  fmt-check              Check formatting"
	@echo "  snapshot               Create gas snapshot"
	@echo "  snapshot-diff          Compare gas snapshot"
	@echo ""
	@echo "Signing targets:"
	@echo "  checkout-signer-tool   Checkout task signing tool"
	@echo "  sign                   Run signing tool"
	@echo "  sign-task              Checkout and run signing tool"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean-all              Remove all artifacts"
	@echo "  verify-env             Verify environment variables"
	@echo "  list-templates         List available templates"
	@echo "  version                Show configuration"
	@echo "  help                   Show this help message"
	@echo ""
	@echo "CI/CD targets:"
	@echo "  ci                     Run quick CI pipeline"
	@echo "  ci-full                Run full CI pipeline with coverage"
	@echo ""
	@echo "Environment variables:"
	@echo "  FOUNDRY_COMMIT         Foundry commit to use (current: $(FOUNDRY_COMMIT))"
	@echo "  OP_COMMIT              Optimism commit (required)"
	@echo "  BASE_CONTRACTS_COMMIT  Base contracts commit (required)"
	@echo "  SIGNER_TOOL_COMMIT     Signer tool commit (current: $(SIGNER_TOOL_COMMIT))"
	@echo ""
	@echo "Examples:"
	@echo "  make setup-task network=mainnet task=deploy-token"
	@echo "  make deps"
	@echo "  make solidity-test-quick"
	@echo "  make ci"
