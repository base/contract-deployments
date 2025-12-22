include ../.env
include .env

include ../../Makefile

.PHONY: install-rust
install-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	rustup toolchain install $(RUST_TOOLCHAIN) && \
    rustup default $(RUST_TOOLCHAIN)

.PHONY: install-solana-cli
install-solana-cli:
	curl -sSfL https://release.anza.xyz/v$(SOLANA_VERSION)/install | sh

.PHONY: install-anchor
install-anchor:
	cargo install --git https://github.com/coral-xyz/anchor --tag v$(ANCHOR_VERSION) anchor-cli --force

.PHONY: install-bun
install-bun:
	curl -fsSL https://bun.sh/install | bash

.PHONY: setup-deps
setup-deps: install-rust install-solana-cli install-anchor install-bun

##
# MCM Bridge Config Update Workflow
##

# Step 1: Create set partner oracle config proposal
.PHONY: step1-create-set-partner-oracle-config-proposal
step1-create-set-partner-oracle-config-proposal:
	@echo "==> Step 1: Creating set partner oracle config MCM proposal..."
	@make mcm-proposal-bridge-set-partner-oracle-config \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT)

# Step 2: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 9: Signing proposal..."
	make mcm-sign

# Step 3: Execute proposal (signatures + set-root + execute)
.PHONY: step3-execute-proposal
step3-execute-proposal:
	@echo "==> Step 10: Executing proposal..."
	make mcm-signatures-all
	make mcm-proposal-set-root
	@echo "==> Executing operation 1 (SetPartnerOracleConfig)..."
	make mcm-proposal-execute \
		MCM_START_INDEX=0 \
		MCM_OPERATION_COUNT=1 \
		MCM_PROPOSAL_EXECUTE_ARTIFACT=artifacts/mcm-proposal-execute-op1.json
	@echo "==> Executing operation 2 (Upgrade)..."
	make mcm-proposal-execute \
		MCM_START_INDEX=1 \
		MCM_OPERATION_COUNT=1 \
		MCM_PROPOSAL_EXECUTE_ARTIFACT=artifacts/mcm-proposal-execute-op2.json