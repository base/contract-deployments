include ../.env
include .env

include ../../Makefile

##
# MCM Program Upgrade Workflow
##

# Step 1: Write program buffer
.PHONY: step1-write-buffer
step1-write-buffer:
	@echo "==> Step 1: Writing program buffer..."
	make sol-write-buffer

# Step 2: Transfer buffer authority to MCM
.PHONY: step2-transfer-buffer
step2-transfer-buffer:
	@echo "==> Step 2: Transferring buffer authority to MCM..."
	make sol-set-buffer-authority

# Step 2.5: Generate set-buffer-authority artifacts (use solana explorer to get the signature of the set-buffer-authority tx)
.PHONY: step7.5-generate-set-buffer-authority-artifacts
step7.5-generate-set-buffer-authority-artifacts:
	@echo "==> Step 7.5: Generating MCM set-buffer-authority artifacts..."
	make sol-confirm SIG=$(SET_BUFFER_AUTHORITY_SIGNATURE) output=artifacts/set-buffer-authority-artifacts.json

# Step 3: Create upgrade proposal
.PHONY: step3-create-proposal
step3-create-proposal:
	@echo "==> Step 3: Creating MCM upgrade proposal..."
	make mcm-proposal-loader-v3-upgrade

# Step 4: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 4: Signing proposal..."
	make mcm-sign

# Step 5: Execute proposal (signatures + set-root + execute)
.PHONY: step5-execute-proposal
step5-execute-proposal:
	@echo "==> Step 5: Executing MCM proposal..."
	make mcm-signatures-all
	make mcm-proposal-all
