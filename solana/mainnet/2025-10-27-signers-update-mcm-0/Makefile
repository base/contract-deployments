include ../.env
include .env

include ../../Makefile

LEDGER_ACCOUNT=1

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
	make mcm-all
	make mcm-signers-print-config
