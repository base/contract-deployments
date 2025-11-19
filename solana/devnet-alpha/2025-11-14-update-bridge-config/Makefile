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
		MCM_PROPOSAL_OUTPUT=set-partner-oracle-config-proposal.json

# Step 2: Clone the bridge repo and apply the id patch
.PHONY: step2-clone-bridge
step2-clone-bridge:
	@echo "==> Step 2: Cloning and applying id patch..."
	@ rm -rf bridge
	@ git clone --filter=blob:none $(BRIDGE_REPO) bridge
	@ cd bridge && \
		git checkout $(BRIDGE_COMMIT) && \
		git apply ../$(ID_PATCH)

# Step 3: Build the bridge program
.PHONY: step3-build-program
step3-build-program:
	@echo "==> Step 3: Building bridge program..."
	@ cd bridge/solana && \
		cargo-build-sbf

# Step 4: Write program buffer
.PHONY: step4-write-buffer
step4-write-buffer:
	@echo "==> Step 4: Writing program buffer..."
	@ make sol-write-buffer

# Step 5: Transfer buffer authority to MCM
.PHONY: step5-transfer-buffer
step5-transfer-buffer:
	@echo "==> Step 5: Transferring buffer authority to MCM..."
	@ make sol-set-buffer-authority

# Step 6: Generate set-buffer-authority artifacts (use solana explorer to get the signature of the set-buffer-authority tx)
.PHONY: step6-generate-set-buffer-authority-artifacts
step6-generate-set-buffer-authority-artifacts:
	@echo "==> Step 6: Generating MCM set-buffer-authority artifacts..."
	@ make sol-confirm SIG=$(SET_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-buffer-authority-artifacts.json

# Step 7: Create upgrade proposal
.PHONY: step7-create-upgrade-proposal
step7-create-upgrade-proposal:
	@echo "==> Step 7: Creating upgrade proposal..."
	@ make mcm-proposal-loader-v3-upgrade \
		MCM_PROPOSAL_OUTPUT=upgrade-proposal.json

# Step 8: Merge set partner oracle config and upgrade proposals
.PHONY: step8-merge-proposals
step8-merge-proposals:
	@echo "==> Step 8: Merging config and upgrade proposals..."
	@jq -s '.[0] as $$config | .[1] as $$upgrade | $$config | .instructions = ($$config.instructions + $$upgrade.instructions) | .rootMetadata.postOpCount = (.rootMetadata.preOpCount + 2)' \
		set-partner-oracle-config-proposal.json upgrade-proposal.json > $(MCM_PROPOSAL_OUTPUT)
	@echo "  → Cleaning up temporary files..."
	@rm -f set-partner-oracle-config-proposal.json upgrade-proposal.json
	@echo "✓ Merged proposal created: $(MCM_PROPOSAL_OUTPUT)"
	@echo "  - Instructions count: $$(jq '.instructions | length' $(MCM_PROPOSAL_OUTPUT))"
	@echo "  - preOpCount: $$(jq '.rootMetadata.preOpCount' $(MCM_PROPOSAL_OUTPUT))"
	@echo "  - postOpCount: $$(jq '.rootMetadata.postOpCount' $(MCM_PROPOSAL_OUTPUT))"

# Step 9: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 9: Signing proposal..."
	make mcm-sign

# Step 10: Execute proposal (signatures + set-root + execute)
.PHONY: step10-execute-proposal
step10-execute-proposal:
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