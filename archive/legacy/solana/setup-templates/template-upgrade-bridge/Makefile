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
# MCM Program Upgrade Workflow
##

# Step 1: Clone the bridge repo
.PHONY: step1-clone-bridge
step1-clone-bridge:
	@echo "==> Step 1: Cloning the bridge repo..."
	@ rm -rf bridge
	@ git clone --filter=blob:none $(BRIDGE_REPO) bridge
	@ cd bridge && \
		git checkout $(BRIDGE_COMMIT)
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

# Step 5: Generate set-buffer-authority artifacts (use solana explorer to get the signature of the set-buffer-authority tx)
.PHONY: step5-generate-set-buffer-authority-artifacts
step5-generate-set-buffer-authority-artifacts:
	@echo "==> Step 5: Generating MCM set-buffer-authority artifacts..."
	make sol-confirm SIG=$(SET_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-buffer-authority-artifacts.json

# Step 6: Create upgrade proposal
.PHONY: step6-create-proposal
step6-create-proposal:
	@echo "==> Step 6: Creating MCM upgrade proposal..."
	make mcm-proposal-loader-v3-upgrade

# Step 7: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 7: Signing proposal..."
	make mcm-sign

# Step 8: Execute proposal (signatures + set-root + execute)
.PHONY: step8-execute-proposal
step8-execute-proposal:
	@echo "==> Step 8: Executing MCM proposal..."
	make mcm-all
