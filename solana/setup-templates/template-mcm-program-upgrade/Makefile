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

# Step 3: Create upgrade proposal
.PHONY: step3-create-proposal
step3-create-proposal:
	@echo "==> Step 3: Creating MCM upgrade proposal..."
	make mcm-proposal-loader-v3-upgrade

# Step 4: Sign proposal
.PHONY: step4-sign-proposal
step4-sign-proposal:
	@echo "==> Step 4: Signing proposal..."
	make mcm-sign

# Step 5: Execute proposal (signatures + set-root + execute)
.PHONY: step5-execute-proposal
step5-execute-proposal:
	@echo "==> Step 5: Executing MCM proposal..."
	make mcm-signatures-all
	make mcm-proposal-all
