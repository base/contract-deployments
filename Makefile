# Absolute path to the repo root (the directory containing this Makefile).
# Captured at parse time so the value is correct whether `make` is invoked from
# the repo root or from a task subdirectory whose Makefile does
# `include ../../Makefile`.
REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

GAS_INCREASE_DIR = $(network)/$(shell date +'%Y-%m-%d')-increase-gas-limit
GAS_AND_ELASTICITY_INCREASE_DIR = $(network)/$(shell date +'%Y-%m-%d')-increase-gas-and-elasticity-limit
SAFE_MANAGEMENT_DIR = $(network)/$(shell date +'%Y-%m-%d')-safe-management
FUNDING_DIR = $(network)/$(shell date +'%Y-%m-%d')-funding
SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR = $(network)/$(shell date +'%Y-%m-%d')-set-bridge-partner-threshold
PAUSE_BRIDGE_BASE_DIR = $(network)/$(shell date +'%Y-%m-%d')-pause-bridge-base
PAUSE_SUPERCHAIN_CONFIG_DIR = $(network)/$(shell date +'%Y-%m-%d')-pause-superchain-config

TEMPLATE_GAS_INCREASE = setup-templates/template-gas-increase
TEMPLATE_GAS_AND_ELASTICITY_INCREASE = setup-templates/template-gas-and-elasticity-increase
TEMPLATE_SAFE_MANAGEMENT = setup-templates/template-safe-management
TEMPLATE_FUNDING = setup-templates/template-funding
TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD = setup-templates/template-set-bridge-partner-threshold
TEMPLATE_PAUSE_BRIDGE_BASE = setup-templates/template-pause-bridge-base
TEMPLATE_PAUSE_SUPERCHAIN_CONFIG = setup-templates/template-pause-superchain-config

##
# Toolchain bootstrap (mise)
##
# Every signer- and contributor-facing target depends on `bootstrap-mise`, so a
# fresh clone needs nothing more than `make sign-task` (or `make deps`, etc.) to
# get the exact pinned toolchain from `mise.toml`. We deliberately invoke each
# tool via `mise exec --` rather than relying on `mise activate`, so that the
# user's interactive shell environment (e.g. a global `foundryup` install) is
# left untouched.
#
# Resolve mise: prefer one already on PATH, otherwise the path the vendored
# installer writes to (`$HOME/.local/bin/mise`).
MISE := $(shell command -v mise 2>/dev/null || echo $(HOME)/.local/bin/mise)
MISE_EXEC := $(MISE) exec --

.PHONY: bootstrap-mise
bootstrap-mise:
	@if ! command -v mise >/dev/null 2>&1 && [ ! -x "$(HOME)/.local/bin/mise" ]; then \
		echo "mise not found — installing to \$$HOME/.local/bin/mise"; \
		MISE_QUIET=1 MISE_INSTALL_HELP=0 sh $(REPO_ROOT)/scripts/install-mise.sh; \
	fi
	@$(MISE) trust --quiet $(REPO_ROOT)/mise.toml >/dev/null
	@$(MISE) install --quiet --cd $(REPO_ROOT)
	@# The signer-tool re-executes the validation file's `cmd` in a fresh shell.
	@# That command uses bare `mise exec --` (see Multisig.mk GEN_VALIDATION) so
	@# the validation JSON stays portable across machines. If `mise` is not on
	@# the user's PATH, that re-execution will fail with "command not found".
	@if ! command -v mise >/dev/null 2>&1; then \
		echo ""; \
		echo "WARNING: 'mise' is installed at $(HOME)/.local/bin/mise but is not on your PATH."; \
		echo "         The signer-tool needs 'mise' on PATH to re-execute validation file 'cmd' fields."; \
		echo "         Add this to your shell config (e.g. ~/.zshrc or ~/.bashrc) and restart your shell:"; \
		echo ""; \
		echo "             export PATH=\"\$$HOME/.local/bin:\$$PATH\""; \
		echo ""; \
		echo "         (Or, for full mise integration: eval \"\$$(mise activate \$$(basename \$$SHELL))\")"; \
		echo ""; \
	fi

# Resolve GOPATH lazily via mise so it works after `bootstrap-mise` installs go.
# Recursive (`=`) expansion defers `go env GOPATH` to recipe time, when mise is
# guaranteed to be on disk.
ifndef GOPATH
GOPATH = $(shell $(MISE_EXEC) go env GOPATH 2>/dev/null)
export GOPATH
endif

##
# Project Setup
##
# Run `make setup-gas-increase network=<network>`
setup-gas-increase:
	rm -rf $(TEMPLATE_GAS_INCREASE)/cache $(TEMPLATE_GAS_INCREASE)/lib $(TEMPLATE_GAS_INCREASE)/out
	cp -r $(TEMPLATE_GAS_INCREASE) $(GAS_INCREASE_DIR)
	mkdir -p $(network)/signatures/$(notdir $(GAS_INCREASE_DIR))

# Run `make setup-gas-increase network=<network>`
setup-gas-and-elasticity-increase:
	rm -rf $(TEMPLATE_GAS_AND_ELASTICITY_INCREASE)/cache $(TEMPLATE_GAS_AND_ELASTICITY_INCREASE)/lib $(TEMPLATE_GAS_AND_ELASTICITY_INCREASE)/out
	cp -r $(TEMPLATE_GAS_AND_ELASTICITY_INCREASE) $(GAS_AND_ELASTICITY_INCREASE_DIR)
	mkdir -p $(network)/signatures/$(notdir $(GAS_AND_ELASTICITY_INCREASE_DIR))

# Run `make setup-safe-management network=<network>`
setup-safe-management:
	rm -rf $(TEMPLATE_SAFE_MANAGEMENT)/cache $(TEMPLATE_SAFE_MANAGEMENT)/lib $(TEMPLATE_SAFE_MANAGEMENT)/out
	cp -r $(TEMPLATE_SAFE_MANAGEMENT) $(SAFE_MANAGEMENT_DIR)
	mkdir -p $(network)/signatures/$(notdir $(SAFE_MANAGEMENT_DIR))

# Run `make setup-funding network=<network>`
setup-funding:
	rm -rf $(TEMPLATE_FUNDING)/cache $(TEMPLATE_FUNDING)/lib $(TEMPLATE_FUNDING)/out
	cp -r $(TEMPLATE_FUNDING) $(FUNDING_DIR)
	mkdir -p $(network)/signatures/$(notdir $(FUNDING_DIR))

# Run `make setup-bridge-partner-threshold network=<network>`
setup-bridge-partner-threshold:
	rm -rf $(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD)/cache $(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD)/lib $(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD)/out
	cp -r $(TEMPLATE_SET_BASE_BRIDGE_PARTNER_THRESHOLD) $(SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR)
	mkdir -p $(network)/signatures/$(notdir $(SET_BASE_BRIDGE_PARTNER_THRESHOLD_DIR))

# Run `make setup-bridge-pause network=<network>`
setup-bridge-pause:
	rm -rf $(TEMPLATE_PAUSE_BRIDGE_BASE)/cache $(TEMPLATE_PAUSE_BRIDGE_BASE)/lib $(TEMPLATE_PAUSE_BRIDGE_BASE)/out
	cp -r $(TEMPLATE_PAUSE_BRIDGE_BASE) $(PAUSE_BRIDGE_BASE_DIR)
	mkdir -p $(network)/signatures/$(notdir $(PAUSE_BRIDGE_BASE_DIR))

# Run `make setup-superchain-config-pause network=<network>`
setup-superchain-config-pause:
	rm -rf $(TEMPLATE_PAUSE_SUPERCHAIN_CONFIG)/cache $(TEMPLATE_PAUSE_SUPERCHAIN_CONFIG)/lib $(TEMPLATE_PAUSE_SUPERCHAIN_CONFIG)/out
	cp -r $(TEMPLATE_PAUSE_SUPERCHAIN_CONFIG) $(PAUSE_SUPERCHAIN_CONFIG_DIR)
	mkdir -p $(network)/signatures/$(notdir $(PAUSE_SUPERCHAIN_CONFIG_DIR))

##
# Solidity Setup
##
# Pinned tag for openzeppelin-contracts-upgradeable, installed via clone-oz-upgradeable.
OZ_UPGRADEABLE_TAG=v4.7.3
LIB_KECCAK_COMMIT=3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9

.PHONY: deps
deps: bootstrap-mise install-eip712sign clean-lib forge-deps

.PHONY: install-eip712sign
install-eip712sign:
	$(MISE_EXEC) go install github.com/base/eip712sign@v0.0.11

.PHONY: clean-lib
clean-lib:
	rm -rf lib

.PHONY: forge-deps
forge-deps:
	[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	$(MISE_EXEC) forge install --no-git github.com/foundry-rs/forge-std@0844d7e1fc5e60d77b68e469bff60265f236c398 \
	github.com/Vectorized/solady@502cc1ea718e6fa73b380635ee0868b0740595f0 \
	github.com/ethereum-optimism/lib-keccak@$(LIB_KECCAK_COMMIT) \
	github.com/base/contracts@$(BASE_CONTRACTS_COMMIT)

##
# Task Signer Tool
##
SIGNER_TOOL_COMMIT=8b50397aa06533e2ccbad1fe8b0694367177d87f
SIGNER_TOOL_PATH=signer-tool

.PHONY: checkout-signer-tool
checkout-signer-tool:
	[ -n "$(SIGNER_TOOL_COMMIT)" ] || (echo "SIGNER_TOOL_COMMIT must be set in .env" && exit 1)
	rm -rf $(SIGNER_TOOL_PATH)
	mkdir -p $(SIGNER_TOOL_PATH)
	cd $(SIGNER_TOOL_PATH); \
	git init; \
	git remote add origin https://github.com/base/task-signing-tool.git; \
	git fetch --depth=1 origin $(SIGNER_TOOL_COMMIT); \
	git reset --hard FETCH_HEAD

# Checkout and install signer-tool dependencies (used as a prerequisite by gen-validation targets)
.PHONY: deps-signer-tool
deps-signer-tool: bootstrap-mise checkout-signer-tool
	cd $(SIGNER_TOOL_PATH) && $(MISE_EXEC) npm ci

.PHONY: sign-task
sign-task: bootstrap-mise checkout-signer-tool
	cd $(SIGNER_TOOL_PATH); \
	$(MISE_EXEC) npm ci; \
	$(MISE_EXEC) npm run dev

# Task origin signature variables (auto-derived, overridable).
# These targets are designed to be invoked from task subdirectories
# (e.g. sepolia/2026-02-19-superchain-separation/) that include this Makefile.
TASK_NAME ?= $(notdir $(CURDIR))
SIGNATURE_DIR ?= $(CURDIR)/../signatures/$(TASK_NAME)

.PHONY: sign-as-task-creator
sign-as-task-creator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder $(CURDIR) \
		--signature-path $(SIGNATURE_DIR)

.PHONY: sign-as-base-facilitator
sign-as-base-facilitator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder $(CURDIR) \
		--signature-path $(SIGNATURE_DIR) \
		--facilitator base

.PHONY: sign-as-sc-facilitator
sign-as-sc-facilitator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder $(CURDIR) \
		--signature-path $(SIGNATURE_DIR) \
		--facilitator security-council
