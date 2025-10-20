include ../.env
include .env

include ../../Makefile

##
# MCM Signers Update Workflow
##

# Step 1: Create signers update proposal
.PHONY: step1-create-proposal
step1-create-proposal:
	@echo "==> Step 1: Creating MCM signers update proposal..."
	make mcm-proposal-update-signers

# Step 2: Sign proposal
.PHONY: sign
sign:
	@echo "==> Step 2: Signing proposal..."
	make mcm-sign

# Step 3: Execute proposal (signatures + set-root + execute)
.PHONY: step3-execute-proposal
step3-execute-proposal:
	@echo "==> Step 3: Executing MCM proposal..."
	make mcm-signatures-all
	make mcm-proposal-all
