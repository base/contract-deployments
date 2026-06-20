include ../.env
include .env

include ../../Makefile

##
# Project Setup
##

.PHONY: install-rust
install-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

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

# Step 1: Clone and patch the MCM program
.PHONY: step1-clone-patch-and-build
step1-clone-patch-and-build:
	@echo "==> Step 1: Cloning and patching the MCM program..."
	rm -rf chainlink-ccip
	git clone --filter=blob:none $(MCM_REPO) chainlink-ccip
	cd chainlink-ccip && \
		git checkout $(MCM_AUDITED_COMMIT) && \
		git apply ../$(INVOKE_SIGNED_PATCH) && \
		git apply ../$(EIP712_PATCH) && \
		git apply ../$(SIMPLIFY_EIP712_PATCH) && \
		git apply ../$(ID_PATCH)
	cd chainlink-ccip/chains/solana/contracts && \
		anchor build -p mcm

# Step 2: Write program buffer
.PHONY: step2-write-buffer
step2-write-buffer:
	@echo "==> Step 2: Writing program buffer..."
	make sol-write-buffer

# Step 3: Transfer buffer authority to MCM
.PHONY: step3-transfer-buffer
step3-transfer-buffer:
	@echo "==> Step 2: Transferring buffer authority to MCM..."
	make sol-set-buffer-authority

# Step 3.5: Generate set-buffer-authority artifacts (use solana explorer to get the signature of the set-buffer-authority tx)
.PHONY: step3.5-generate-set-buffer-authority-artifacts
step3.5-generate-set-buffer-authority-artifacts:
	@echo "==> Step 3.5: Generating MCM set-buffer-authority artifacts..."
	make sol-confirm SIG=$(SET_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-buffer-authority-artifacts.json

# Step 4: Create upgrade proposal
.PHONY: step4-create-proposal
step4-create-proposal:
	@echo "==> Step 4: Creating MCM upgrade proposal..."
	make mcm-proposal-loader-v3-upgrade

# Step 5: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 5: Signing proposal..."
	make mcm-sign

# Step 6: Execute proposal (signatures + set-root + execute)
.PHONY: step6-execute-proposal
step6-execute-proposal:
	@echo "==> Step 6: Executing MCM proposal..."
	make mcm-signatures-all
	make mcm-proposal-all
