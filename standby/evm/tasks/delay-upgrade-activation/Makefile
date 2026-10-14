include $(shell git rev-parse --show-toplevel)/scripts/Standby.mk

SCRIPT_FILE := ../../standby/evm/tasks/$(notdir $(CURDIR))/script/DelayUpgradeActivation.s.sol
ifeq ($(PROJECT_DIR),$(CURDIR))
SCRIPT_FILE := script/DelayUpgradeActivation.s.sol
endif
SCRIPT_NAME := $(SCRIPT_FILE):DelayUpgradeActivation
RESPONDER = $(shell $(MISE_EXEC) cast call $(PROTOCOL_VERSIONS_PROXY) "incidentResponder()(address)" --rpc-url $(RPC_URL))
CB_SENDER = $(shell $(MISE_EXEC) cast call $(RESPONDER) "getOwners()(address[])" --rpc-url $(RPC_URL) | tr -d '[]' | cut -d',' -f1)

UPDATE_ENV = PROTOCOL_VERSIONS_PROXY=$(PROTOCOL_VERSIONS_PROXY) \
	UPGRADE_ID=$(UPGRADE_ID) EXPECTED_CURRENT_TIMESTAMP=$(EXPECTED_CURRENT_TIMESTAMP) NEW_TIMESTAMP=$(NEW_TIMESTAMP)

.PHONY: validate-config build validate gen-validation-cb execute verify
validate-config:
	@python3 $(REPO_ROOT)/scripts/standby-task.py check-delay --repo "$(REPO_ROOT)" --task "$(CURDIR)" --network "$(TASK_NETWORK)"

build: validate-config bootstrap-mise
	cd $(PROJECT_DIR) && $(MISE_EXEC) forge build $(SCRIPT_FILE)

validate: validate-config bootstrap-mise
	cd $(PROJECT_DIR) && $(UPDATE_ENV) $(MISE_EXEC) forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) --sig "check()"

gen-validation-cb: validate-config deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(CB_SENDER),base-signer.json,$(UPDATE_ENV))
	@python3 $(REPO_ROOT)/scripts/standby-task.py skip-origin "$(VALIDATIONS_DIR)/base-signer.json"

execute: validate-config bootstrap-mise
	export $(UPDATE_ENV); $(call MULTISIG_EXECUTE,$(SIGNATURES))

verify: validate-config bootstrap-mise
	cd $(PROJECT_DIR) && $(UPDATE_ENV) INCIDENT_MULTISIG=$(INCIDENT_MULTISIG) $(MISE_EXEC) forge script \
		--rpc-url $(RPC_URL) $(SCRIPT_FILE):VerifyUpgradeDelay --sig "run()"
