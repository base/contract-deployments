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
	sh -c "$(curl -sSfL https://release.anza.xyz/v$(SOLANA_VERSION)/install)"

.PHONY: install-anchor
install-anchor:
	cargo install --git https://github.com/coral-xyz/anchor --tag v$(ANCHOR_VERSION) anchor-cli --force

.PHONY: install-bun
install-bun:
	curl -fsSL https://bun.sh/install | bash

.PHONY: deps
deps: install-rust install-solana-cli install-anchor install-bun

##
# Deployment Workflow
##

# Step 1: Clone and build bridge programs
.PHONY: step1-clone-and-build
step1-clone-and-build:
	@echo "==> Step 1: Cloning and building bridge programs..."
	rm -rf bridge
	git clone --filter=blob:none $(BRIDGE_REPO) bridge
	cd bridge && \
		git checkout $(BRIDGE_AUDITED_COMMIT)
	cd bridge/scripts && \
		bun install
	cd bridge/scripts && \
		bun cli sol build \
		--deploy-env $(DEPLOY_ENV) \
		--bridge-program-kp ../../$(BRIDGE_KP) \
		--base-relayer-program-kp ../../$(BASE_RELAYER_KP)

# Step 2: Deploy programs
.PHONY: step2-deploy-programs
step2-deploy-programs:
	@echo "==> Step 2: Deploying programs..."
	cd bridge/scripts && \
		bun cli sol deploy \
		--deploy-env $(DEPLOY_ENV) \
		--program bridge \
		--program-kp ../../$(BRIDGE_KP) \
		--deployer-kp ../../$(DEPLOYER_KP)
	cd bridge/scripts && \
		bun cli sol deploy \
		--deploy-env $(DEPLOY_ENV) \
		--program base-relayer \
		--program-kp ../../$(BASE_RELAYER_KP) \
		--deployer-kp ../../$(DEPLOYER_KP)

# Step 3: Initialize programs
.PHONY: step3-init-programs
step3-init-programs:
	@echo "==> Step 3: Initializing programs..."
	make sol-confirm-cmd \
		cmd="cd bridge/scripts && \
			bun cli sol bridge initialize \
			--program-id $(BRIDGE_PROGRAM_ID) \
			--rpc-url $(SOL_RPC_URL) \
			--payer-kp ../../$(DEPLOYER_KP) \
			--guardian-kp ../../$(DEPLOYER_KP) \
			--eip1559-target $(BRIDGE_EIP1559_TARGET) \
			--eip1559-denominator $(BRIDGE_EIP1559_DENOMINATOR) \
			--eip1559-window-duration-seconds $(BRIDGE_EIP1559_WINDOW_DURATION_SECONDS) \
			--eip1559-minimum-base-fee $(BRIDGE_EIP1559_MINIMUM_BASE_FEE) \
			--gas-per-call $(BRIDGE_GAS_PER_CALL) \
			--gas-cost-scaler $(BRIDGE_GAS_COST_SCALER) \
			--gas-cost-scaler-dp $(BRIDGE_GAS_COST_SCALER_DP) \
			--gas-fee-receiver $(BRIDGE_GAS_FEE_RECEIVER) \
			--protocol-block-interval-requirement $(BRIDGE_PROTOCOL_BLOCK_INTERVAL_REQUIREMENT) \
			--buffer-max-call-buffer-size $(BRIDGE_BUFFER_MAX_CALL_BUFFER_SIZE) \
			--base-oracle-threshold $(BRIDGE_BASE_ORACLE_THRESHOLD) \
			--base-oracle-signer-count $(BRIDGE_BASE_ORACLE_SIGNER_COUNT) \
			--base-oracle-signers $(BRIDGE_BASE_ORACLE_SIGNERS) \
			--partner-oracle-required-threshold $(BRIDGE_PARTNER_ORACLE_REQUIRED_THRESHOLD)" \
		output=artifacts/init-bridge.json
	make sol-confirm-cmd \
		cmd="cd bridge/scripts && \
			bun cli sol base-relayer initialize \
			--program-id $(BASE_RELAYER_PROGRAM_ID) \
			--rpc-url $(SOL_RPC_URL) \
			--payer-kp ../../$(DEPLOYER_KP) \
			--guardian-kp ../../$(DEPLOYER_KP) \
			--eip1559-target $(BASE_RELAYER_EIP1559_TARGET) \
			--eip1559-denominator $(BASE_RELAYER_EIP1559_DENOMINATOR) \
			--eip1559-window-duration-seconds $(BASE_RELAYER_EIP1559_WINDOW_DURATION_SECONDS) \
			--eip1559-minimum-base-fee $(BASE_RELAYER_EIP1559_MINIMUM_BASE_FEE) \
			--min-gas-limit-per-message $(BASE_RELAYER_MIN_GAS_LIMIT_PER_MESSAGE) \
			--max-gas-limit-per-message $(BASE_RELAYER_MAX_GAS_LIMIT_PER_MESSAGE) \
			--gas-cost-scaler $(BASE_RELAYER_GAS_COST_SCALER) \
			--gas-cost-scaler-dp $(BASE_RELAYER_GAS_COST_SCALER_DP) \
			--gas-fee-receiver $(BASE_RELAYER_GAS_FEE_RECEIVER)" \
		output=artifacts/init-base-relayer.json

# Step 4: Print SOL vault
.PHONY: step4-print-sol-vault
step4-print-sol-vault:
	@echo "==> Step 4: Printing SOL vault..."
	cd bridge/scripts && \
		bun cli sol bridge sol-vault \
		--bridge-program $(BRIDGE_PROGRAM_ID) \
		--remote-token $(SOL_REMOTE_TOKEN)

# Step 4: Print SOL vault and fund it
.PHONY: step4-fund-sol-vault
step4-fund-sol-vault:
	@echo "==> Step 4: Funding SOL vault..."
	make sol-transfer
