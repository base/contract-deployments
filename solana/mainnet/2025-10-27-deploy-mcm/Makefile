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
# Deployment Workflow
##

# Step 1: Clone and patch the MCM program
.PHONY: step1-clone-and-patch
step1-clone-and-patch:
	@echo "==> Step 1: Cloning and patching the MCM program..."
	rm -rf chainlink-ccip
	git clone --filter=blob:none $(MCM_REPO) chainlink-ccip
	cd chainlink-ccip && \
		git checkout $(MCM_COMMIT)

# Step 2: Build and deploy the MCM program
.PHONY: step2-build-and-deploy
step2-build-and-deploy:
	@echo "==> Step 2: Building and deploying the MCM program..."
	mkdir -p chainlink-ccip/chains/solana/contracts/target/deploy/ && \
		cp $(MCM_KEYPAIR) chainlink-ccip/chains/solana/contracts/target/deploy/mcm-keypair.json
	cd chainlink-ccip/chains/solana/contracts && \
		anchor keys sync && \
		anchor build -p mcm && \
		anchor deploy --provider.cluster $(CLUSTER) --provider.wallet $(AUTHORITY) -p mcm

# Step 3: Generate deploy artifacts (use solana explorer to get the signature of the deployWithMaxDataLen tx)
.PHONY: step3-generate-deploy-artifacts
step3-generate-deploy-artifacts:
	@echo "==> Step 3: Generating MCM deploy artifacts..."
	make sol-confirm SIG=$(MCM_DEPLOY_SIGNATURE) output=artifacts/mcm-deploy-artifacts.json

# Step 4: Initialize the multisigs(inherited from parent)
.PHONY: step4-init-multisigs
step4-init-multisigs:
	@echo "==> Step 4: Initializing MCM multisigs..."
	make mcm-multisig-init \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_0) \
		MCM_MULTISIG_INIT_ARTIFACT=$(MCM_MULTISIG_INIT_ARTIFACT_0)
	make mcm-multisig-init \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_1) \
		MCM_MULTISIG_INIT_ARTIFACT=$(MCM_MULTISIG_INIT_ARTIFACT_1)
	@echo "==> MCM multisig authority for multisig 0..."
	make mcm-multisig-print-authority \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_0)
	@echo "==> MCM multisig authority for multisig 1..."
	make mcm-multisig-print-authority \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_1)

# Step 5: Initialize the signers for multisigs(inherited from parent)
.PHONY: step5-init-signers
step5-init-signers:
	@echo "==> Step 5: Initializing MCM signers for multisigs..."
	make mcm-signers-all \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_0) \
		MCM_SIGNERS_INIT_ARTIFACT=$(MCM_SIGNERS_INIT_ARTIFACT_0) \
		MCM_SIGNERS_APPEND_ARTIFACT=$(MCM_SIGNERS_APPEND_ARTIFACT_0) \
		MCM_SIGNERS_FINALIZE_ARTIFACT=$(MCM_SIGNERS_FINALIZE_ARTIFACT_0) \
		MCM_SIGNERS_SET_CONFIG_ARTIFACT=$(MCM_SIGNERS_SET_CONFIG_ARTIFACT_0)
	make mcm-signers-all \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_1) \
		MCM_SIGNERS_INIT_ARTIFACT=$(MCM_SIGNERS_INIT_ARTIFACT_1) \
		MCM_SIGNERS_APPEND_ARTIFACT=$(MCM_SIGNERS_APPEND_ARTIFACT_1) \
		MCM_SIGNERS_FINALIZE_ARTIFACT=$(MCM_SIGNERS_FINALIZE_ARTIFACT_1) \
		MCM_SIGNERS_SET_CONFIG_ARTIFACT=$(MCM_SIGNERS_SET_CONFIG_ARTIFACT_1)

# Step 6: Create accept-ownership proposals (inherited from parent)
.PHONY: step6-create-accept-ownership-proposals
step6-create-accept-ownership-proposals:
	@echo "==> Step 6: Creating MCM accept-ownership proposals..."
	make mcm-proposal-accept-ownership \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_0) \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_0)
	make mcm-proposal-accept-ownership \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_1) \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_1)

# Step 7: Sign the proposals (inherited from parent)
.PHONY: step7-sign-proposals
step7-sign-proposals:
	@echo "==> Step 7: Signing MCM proposals..."
	make mcm-sign \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_0)
	make mcm-sign \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_1)

# Step 8: Execute ownership transfers (inherited from parent)
.PHONY: step8-execute-ownership-transfers
step8-execute-ownership-transfers:
	@echo "==> Step 8: Executing MCM ownership transfers..."
	make mcm-ownership-transfer \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_0) \
		MCM_PROPOSED_OWNER=$(MCM_AUTHORITY_0) \
		MCM_OWNERSHIP_TRANSFER_ARTIFACT=$(MCM_OWNERSHIP_TRANSFER_ARTIFACT_0)
	make mcm-all \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_0) \
		MCM_SIGNATURES=$(MCM_SIGNATURES_0) \
		MCM_SIGNATURES_INIT_ARTIFACT=$(MCM_SIGNATURES_INIT_ARTIFACT_0) \
		MCM_SIGNATURES_APPEND_ARTIFACT=$(MCM_SIGNATURES_APPEND_ARTIFACT_0) \
		MCM_SIGNATURES_FINALIZE_ARTIFACT=$(MCM_SIGNATURES_FINALIZE_ARTIFACT_0) \
		MCM_PROPOSAL_SET_ROOT_ARTIFACT=$(MCM_PROPOSAL_SET_ROOT_ARTIFACT_0) \
		MCM_PROPOSAL_EXECUTE_ARTIFACT=$(MCM_PROPOSAL_EXECUTE_ARTIFACT_0)
	make mcm-ownership-transfer \
		MCM_MULTISIG_ID=$(MCM_MULTISIG_ID_1) \
		MCM_PROPOSED_OWNER=$(MCM_AUTHORITY_1) \
		MCM_OWNERSHIP_TRANSFER_ARTIFACT=$(MCM_OWNERSHIP_TRANSFER_ARTIFACT_1)
	make mcm-all \
		MCM_PROPOSAL_OUTPUT=$(MCM_PROPOSAL_OUTPUT_1) \
		MCM_SIGNATURES=$(MCM_SIGNATURES_1) \
		MCM_SIGNATURES_INIT_ARTIFACT=$(MCM_SIGNATURES_INIT_ARTIFACT_1) \
		MCM_SIGNATURES_APPEND_ARTIFACT=$(MCM_SIGNATURES_APPEND_ARTIFACT_1) \
		MCM_SIGNATURES_FINALIZE_ARTIFACT=$(MCM_SIGNATURES_FINALIZE_ARTIFACT_1) \
		MCM_PROPOSAL_SET_ROOT_ARTIFACT=$(MCM_PROPOSAL_SET_ROOT_ARTIFACT_1) \
		MCM_PROPOSAL_EXECUTE_ARTIFACT=$(MCM_PROPOSAL_EXECUTE_ARTIFACT_1)

# Step 9: Transfer upgrade authority (inherited from parent)
.PHONY: step9-transfer-upgrade-authority
step9-transfer-upgrade-authority:
	@echo "==> Step 9: Transferring MCM upgrade authority..."
	make sol-program-set-upgrade-authority
	make sol-program-show

# Step 10: Generate set-upgrade-authority artifacts (use solana explorer to get the signature of the set-upgrade-authority tx)
.PHONY: step10-generate-set-upgrade-authority-artifacts
step10-generate-set-upgrade-authority-artifacts:
	@echo "==> Step 10: Generating MCM set-upgrade-authority artifacts..."
	make sol-confirm SIG=$(SET_UPGRADE_AUTHORITY_SIGNATURE) output=artifacts/set-upgrade-authority-artifacts.json

# Step 11: Fund MCM authorities (inherited from parent)
.PHONY: step11-fund-mcm-authorities
step11-fund-mcm-authorities:
	@echo "==> Step 11: Funding MCM authorities..."
	make sol-transfer SOL_RECIPIENT=$(MCM_AUTHORITY_0) output=artifacts/fund-mcm-authority-0.json
	make sol-transfer SOL_RECIPIENT=$(MCM_AUTHORITY_1) output=artifacts/fund-mcm-authority-1.json
