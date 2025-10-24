include ../.env
include .env

include ../../Makefile

##
# MCM Bridge Pause/Unpause Workflow
##

# Step 1: Create merged pause/unpause proposal
.PHONY: step1-create-proposal
step1-create-proposal:
	@echo "==> Step 1: Creating merged pause/unpause MCM proposal..."
	@echo "  → Creating pause proposal..."
	@make mcm-proposal-bridge-pause \
		PAUSED=true \
		MCM_PROPOSAL_OUTPUT=pause-proposal.json
	@echo "  → Creating unpause proposal..."
	@make mcm-proposal-bridge-pause \
		PAUSED=false \
		MCM_PROPOSAL_OUTPUT=unpause-proposal.json
	@echo "  → Merging proposals..."
	@jq -s '.[0] as $$pause | .[1] as $$unpause | $$pause | .instructions = ($$pause.instructions + $$unpause.instructions) | .rootMetadata.postOpCount = (.rootMetadata.preOpCount + 2)' \
		pause-proposal.json unpause-proposal.json > proposal.json
	@echo "  → Cleaning up temporary files..."
	@rm -f pause-proposal.json unpause-proposal.json
	@echo "✓ Merged proposal created: proposal.json"
	@echo "  - Instructions count: $$(jq '.instructions | length' proposal.json)"
	@echo "  - preOpCount: $$(jq '.rootMetadata.preOpCount' proposal.json)"
	@echo "  - postOpCount: $$(jq '.rootMetadata.postOpCount' proposal.json)"

# Step 2: Sign proposal	
.PHONY: sign
sign:
	@echo "==> Step 2: Signing proposal..."
	@make mcm-sign

# Step 3: Register proposal (signatures + set-root)
.PHONY: step3-register-proposal
step3-register-proposal:
	@echo "==> Step 3: Registering MCM proposal..."
	@make mcm-signatures-all
	@make mcm-proposal-set-root

# Step 4: Execute pause proposal
.PHONY: step4-execute-pause
step4-execute-pause:
	@echo "==> Step 4: Executing MCM pause proposal..."
	@make mcm-proposal-execute \
		MCM_START_INDEX=0 \
		MCM_OPERATION_COUNT=1
	@mv artifacts/mcm-proposal-execute.json artifacts/mcm-pause-proposal-execute.json

# Step 5: Execute unpause proposal
.PHONY: step5-execute-unpause
step5-execute-unpause:
	@echo "==> Step 5: Executing MCM unpause proposal..."
	@make mcm-proposal-execute \
		MCM_START_INDEX=1 \
		MCM_OPERATION_COUNT=1
	@mv artifacts/mcm-proposal-execute.json artifacts/mcm-unpause-proposal-execute.json