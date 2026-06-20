# Absolute path to the repo root (the directory containing this Makefile).
# Captured at parse time so the value is correct whether `make` is invoked from
# the repo root or from a task subdirectory whose Makefile does
# `include ../../Makefile`.
REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

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
SIGNER_TOOL_COMMIT=5461faaacba3d7b0dfc942e9a1ed631e1be84621
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
# Legacy task subdirectories sign their own folder by default. The active EVM
# task overrides TASK_ORIGIN_DIR to sign active/evm/config/mainnet.
TASK_NAME ?= $(notdir $(CURDIR))
TASK_ORIGIN_DIR ?= $(CURDIR)
SIGNATURE_DIR ?= $(CURDIR)/../signatures/$(TASK_NAME)

.PHONY: sign-as-task-creator
sign-as-task-creator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder "$(TASK_ORIGIN_DIR)" \
		--signature-path "$(SIGNATURE_DIR)"

.PHONY: sign-as-base-facilitator
sign-as-base-facilitator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder "$(TASK_ORIGIN_DIR)" \
		--signature-path "$(SIGNATURE_DIR)" \
		--facilitator base

.PHONY: sign-as-sc-facilitator
sign-as-sc-facilitator: deps-signer-tool
	mkdir -p "$(SIGNATURE_DIR)"
	cd $(SIGNER_TOOL_PATH) && \
		$(MISE_EXEC) npx tsx scripts/genTaskOriginSig.ts sign \
		--task-folder "$(TASK_ORIGIN_DIR)" \
		--signature-path "$(SIGNATURE_DIR)" \
		--facilitator security-council
