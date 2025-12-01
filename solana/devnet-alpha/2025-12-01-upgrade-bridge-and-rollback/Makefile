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

.PHONY: setup-deps
setup-deps: install-rust install-solana-cli install-anchor

##
# MCM Program Upgrade with Rollback Workflow
##

# Step 1: Clone the bridge repo and apply patch
.PHONY: step1-clone-bridge
step1-clone-bridge:
	@echo "==> Step 1: Cloning and patching the bridge repo..."
	@ rm -rf bridge
	@ git clone --filter=blob:none $(BRIDGE_REPO) bridge
	@ cd bridge && \
		git checkout $(BRIDGE_COMMIT) && \
		git apply ../$(PING_PATCH)
	@ cd bridge/clients/ts && \
		bun install && \
		bun run build
	@ cd bridge/scripts && \
		bun install

# Step 2: Build the bridge programs
.PHONY: step2-build-programs
step2-build-programs:
	@echo "==> Step 2: Building bridge programs..."
	mkdir -p bridge/solana/target/deploy && \
		cp $(BRIDGE_KEYPAIR) bridge/solana/target/deploy/bridge-keypair.json && \
		cp $(BASE_RELAYER_KEYPAIR) bridge/solana/target/deploy/base_relayer-keypair.json && \
	cd bridge/solana && \
		anchor keys sync
	cd bridge/scripts && \
		bun cli sol build \
		--deploy-env $(DEPLOY_ENV) \
		--bridge-program-kp ../../$(BRIDGE_KEYPAIR) \
		--base-relayer-program-kp ../../$(BASE_RELAYER_KEYPAIR)

# Step 3: Write program buffer
.PHONY: step3-write-buffer
step3-write-buffer:
	@echo "==> Step 3: Writing program buffer..."
	make sol-write-buffer

# Step 4: Transfer buffer authority to MCM
.PHONY: step4-transfer-buffer
step4-transfer-buffer:
	@echo "==> Step 4: Transferring buffer authority to MCM..."
	make sol-set-buffer-authority

# Step 5: Generate set-buffer-authority artifacts
.PHONY: step5-generate-set-buffer-authority-artifacts
step5-generate-set-buffer-authority-artifacts:
	@echo "==> Step 5: Generating MCM set-buffer-authority artifacts..."
	make sol-confirm SIG=$(SET_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-buffer-authority-artifacts.json

##
# Rollback Buffer Preparation
##

# Step 6: Dump current program to rollback.so
.PHONY: step6-dump-current-program
step6-dump-current-program:
	@echo "==> Step 6: Dumping current program to rollback.so..."
	solana program dump $(PROGRAM) $(ROLLBACK_PROGRAM_BINARY) --url $(SOL_RPC_URL)

# Step 7: Write rollback buffer
.PHONY: step7-write-rollback-buffer
step7-write-rollback-buffer:
	@echo "==> Step 7: Writing rollback buffer..."
	make sol-write-buffer PROGRAM_BINARY=$(ROLLBACK_PROGRAM_BINARY)

# Step 8: Transfer rollback buffer authority to MCM
.PHONY: step8-transfer-rollback-buffer
step8-transfer-rollback-buffer:
	@echo "==> Step 8: Transferring rollback buffer authority to MCM..."
	make sol-set-buffer-authority BUFFER=$(ROLLBACK_BUFFER)

# Step 9: Generate rollback buffer artifacts
.PHONY: step9-generate-rollback-buffer-artifacts
step9-generate-rollback-buffer-artifacts:
	@echo "==> Step 9: Generating rollback buffer artifacts..."
	make sol-confirm SIG=$(SET_ROLLBACK_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-rollback-buffer-authority-artifacts.json

##
# Proposal Creation and Execution
##

# Step 10: Create merged upgrade/rollback proposal
.PHONY: step10-create-proposal
step10-create-proposal:
	@echo "==> Step 10: Creating merged upgrade/rollback MCM proposal..."
	@echo "  → Creating upgrade proposal..."
	@make mcm-proposal-loader-v3-upgrade \
		MCM_PROPOSAL_OUTPUT=upgrade-proposal.json
	@echo "  → Creating rollback proposal..."
	@make mcm-proposal-loader-v3-upgrade \
		BUFFER=$(ROLLBACK_BUFFER) \
		MCM_PROPOSAL_OUTPUT=rollback-proposal.json
	@echo "  → Merging proposals..."
	@jq -s '.[0] as $$upgrade | .[1] as $$rollback | $$upgrade | .instructions = ($$upgrade.instructions + $$rollback.instructions) | .rootMetadata.postOpCount = (.rootMetadata.preOpCount + 2)' \
		upgrade-proposal.json rollback-proposal.json > proposal.json
	@rm -f upgrade-proposal.json rollback-proposal.json
	@echo "✓ Merged proposal created: proposal.json"
	@echo "  - Instructions count: $$(jq '.instructions | length' proposal.json)"
	@echo "  - preOpCount: $$(jq '.rootMetadata.preOpCount' proposal.json)"
	@echo "  - postOpCount: $$(jq '.rootMetadata.postOpCount' proposal.json)"

# Step 11: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 11: Signing proposal..."
	make mcm-sign

# Step 12: Register proposal (signatures + set-root)
.PHONY: step12-register-proposal
step10-register-proposal:
	@echo "==> Step 12: Registering MCM proposal..."
	@make mcm-signatures-all
	@make mcm-proposal-set-root

# Step 13: Execute upgrade
.PHONY: step13-execute-upgrade
step13-execute-upgrade:
	@echo "==> Step 13: Executing upgrade..."
	@make mcm-proposal-execute MCM_START_INDEX=0 MCM_OPERATION_COUNT=1
	@mv artifacts/mcm-proposal-execute.json artifacts/mcm-upgrade-execute.json

# Step 14: Execute rollback
.PHONY: step12-execute-rollback
step14-execute-rollback:
	@echo "==> Step 14: Executing rollback..."
	@make mcm-proposal-execute MCM_START_INDEX=1 MCM_OPERATION_COUNT=1
	@mv artifacts/mcm-proposal-execute.json artifacts/mcm-rollback-execute.json
