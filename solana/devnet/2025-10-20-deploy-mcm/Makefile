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

.PHONY: deps
deps: install-rust install-solana-cli install-anchor

##
# Deployment Workflow
##

# Step 1: Clone and patch the MCM program
.PHONY: step1-clone-and-patch
step1-clone-and-patch:
	@echo "==> Step 1: Cloning and patching the MCM program..."
	rm -rf chainlink-ccip
	git clone --filter=blob:none $(MCM_REPO) chainlink-ccip
	cd chainlink-ccip && \
		git checkout $(MCM_AUDITED_COMMIT) && \
		git apply ../$(MCM_PROGRAM_PATCH)

# Step 2: Build and deploy the MCM program
.PHONY: step2-build-and-deploy
step2-build-and-deploy:
	@echo "==> Step 2: Building and deploying the MCM program..."
	cd chainlink-ccip/chains/solana/contracts && \
		anchor keys sync && \
		anchor build -p mcm && \
		anchor deploy --provider.cluster $(CLUSTER) --provider.wallet $(AUTHORITY) -p mcm

# Step 2.5: Generate deploy artifacts (use solana explorer to get the signature of the deployWithMaxDataLen tx)
.PHONY: step2.5-generate-deploy-artifacts
step2.5-generate-deploy-artifacts:
	@echo "==> Step 2.5: Generating MCM deploy artifacts..."
	make sol-confirm SIG=$(MCM_DEPLOY_SIGNATURE) output=artifacts/mcm-deploy-artifacts.json

# Step 3: Initialize the multisig (inherited from parent)
.PHONY: step3-init-multisig
step3-init-multisig:
	@echo "==> Step 3: Initializing MCM multisig..."
	make mcm-multisig-init
	make mcm-multisig-print-authority

# Step 4: Initialize the signers (inherited from parent)
.PHONY: step4-init-signers
step4-init-signers:
	@echo "==> Step 4: Initializing MCM signers..."
	make mcm-signers-all

# Step 5: Create accept-ownership proposal (inherited from parent)
.PHONY: step5-create-accept-ownership-proposal
step5-create-accept-ownership-proposal:
	@echo "==> Step 5: Creating MCM accept-ownership proposal..."
	make mcm-proposal-accept-ownership

# Step 5.5: Sign the proposal (inherited from parent)
.PHONY: step5.5-sign-proposal
step5.5-sign-proposal:
	@echo "==> Step 5.5: Signing MCM proposal..."
	make mcm-sign

# Step 6: Execute ownership transfer (inherited from parent)
.PHONY: step6-execute-ownership-transfer
step6-execute-ownership-transfer:
	@echo "==> Step 6: Executing MCM ownership transfer..."
	make mcm-ownership-transfer
	make mcm-all

# Step 7: Transfer upgrade authority (inherited from parent)
.PHONY: step7-transfer-upgrade-authority
step7-transfer-upgrade-authority:
	@echo "==> Step 7: Transferring MCM upgrade authority..."
	make sol-program-set-upgrade-authority
	make sol-program-show

# Step 7.5: Generate set-upgrade-authority artifacts (use solana explorer to get the signature of the set-upgrade-authority tx)
.PHONY: step7.5-generate-set-upgrade-authority-artifacts
step7.5-generate-set-upgrade-authority-artifacts:
	@echo "==> Step 7.5: Generating MCM set-upgrade-authority artifacts..."
	make sol-confirm SIG=$(SET_UPGRADE_AUTHORITY_SIGNATURE) output=artifacts/set-upgrade-authority-artifacts.json
