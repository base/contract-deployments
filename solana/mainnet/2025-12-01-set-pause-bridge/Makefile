include ../.env
include .env

include ../../Makefile

##
# MCM Bridge Pause/Unpause Workflow
##

PAUSE_OUTPUT = proposal-pause.json
UNPAUSE_OUTPUT = proposal-unpause.json

# Step 1: Create pause/unpause proposal
.PHONY: step1-create-proposal-pause
step1-create-proposal-pause:
	@echo "==> Step 1: Creating MCM pause/unpause proposal..."
	MCM_PROPOSAL_OUTPUT=$(PAUSE_OUTPUT) PAUSED=true make mcm-proposal-bridge-pause

.PHONY: step1-create-proposal-unpause
step1-create-proposal-unpause:
	@echo "==> Step 1: Creating MCM pause/unpause proposal..."
	MCM_PROPOSAL_OUTPUT=$(UNPAUSE_OUTPUT) PAUSED=false make mcm-proposal-bridge-pause

# Step 2: Sign proposals
.PHONY: sign-pause
sign-pause:
	@echo "==> Step 2: Signing proposal..."
	@rm -f signatures-pause.txt
	@for i in $$(seq 1 20); do \
		echo "Iteration $$i: Incrementing preOpCount and postOpCount..."; \
		jq '.rootMetadata.preOpCount += 1 | .rootMetadata.postOpCount += 1' $(PAUSE_OUTPUT) > $(PAUSE_OUTPUT).tmp && mv $(PAUSE_OUTPUT).tmp $(PAUSE_OUTPUT); \
		nonce=$$(jq -r '.rootMetadata.preOpCount' $(PAUSE_OUTPUT)); \
		echo "Signing nonce $$nonce..."; \
		MCM_PROPOSAL_OUTPUT=$(PAUSE_OUTPUT) make mcm-sign | tee sign_output.tmp; \
		echo "Nonce: $$nonce" >> signatures-pause.txt; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> signatures-pause.txt || true; \
		echo "" >> signatures-pause.txt; \
		rm sign_output.tmp; \
	done

.PHONY: sign-unpause
sign-unpause:
	@echo "==> Step 2: Signing proposal..."
	@rm -f signatures-unpause.txt
	@for i in $$(seq 1 20); do \
		echo "Iteration $$i: Incrementing preOpCount and postOpCount..."; \
		jq '.rootMetadata.preOpCount += 1 | .rootMetadata.postOpCount += 1' $(UNPAUSE_OUTPUT) > $(UNPAUSE_OUTPUT).tmp && mv $(UNPAUSE_OUTPUT).tmp $(UNPAUSE_OUTPUT); \
		nonce=$$(jq -r '.rootMetadata.preOpCount' $(UNPAUSE_OUTPUT)); \
		echo "Signing nonce $$nonce..."; \
		MCM_PROPOSAL_OUTPUT=$(UNPAUSE_OUTPUT) make mcm-sign | tee sign_output.tmp; \
		echo "Nonce: $$nonce" >> signatures-unpause.txt; \
		grep -E "^Data:|^Signer:|^Signature:" sign_output.tmp >> signatures-unpause.txt || true; \
		echo "" >> signatures-unpause.txt; \
		rm sign_output.tmp; \
	done

# Step 3: Execute proposal (signatures + set-root + execute)
.PHONY: step3-execute-proposal-pause
step3-execute-proposal-pause:
	@echo "==> Step 3: Executing MCM proposal..."
	MCM_PROPOSAL_OUTPUT=$(PAUSE_OUTPUT) make mcm-all

.PHONY: step3-execute-proposal-unpause
step3-execute-proposal-unpause:
	@echo "==> Step 3: Executing MCM proposal..."
	MCM_PROPOSAL_OUTPUT=$(UNPAUSE_OUTPUT) make mcm-all
