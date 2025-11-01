include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

ifndef ROLLBACK_NONCE_OFFSET
override ROLLBACK_NONCE_OFFSET = 1
endif

SCRIPT = IncreaseEip1559ElasticityAndIncreaseGasLimitScript

# Map .env values and export them for child processes
export OLD_GAS_LIMIT NEW_GAS_LIMIT OLD_ELASTICITY NEW_ELASTICITY OWNER_SAFE SYSTEM_CONFIG

.PHONY: gen-validation
gen-validation: checkout-signer-tool run-script

.PHONY: run-script
run-script:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
	$(SCRIPT) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer-upgrade.json;

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))

# TODO: Add rollback commands once config parameter (containing full commands) is added to the signer tool

# Manually swap the old and new values for the gas limit and elasticity when passing them in for the rollback

# .PHONY: gen-validation-rollback
# gen-validation-rollback: checkout-signer-tool run-script-rollback

# .PHONY: run-script-rollback
# run-script-rollback:
# 	cd $(SIGNER_TOOL_PATH); \
# 	npm ci; \
# 		OLD_GAS_LIMIT="$(NEW_GAS_LIMIT)" NEW_GAS_LIMIT="$(OLD_GAS_LIMIT)" \
# 		NEW_ELASTICITY="$(OLD_ELASTICITY)" OLD_ELASTICITY="$(NEW_ELASTICITY)" \
# 	bun run scripts/genValidationFile.ts --rpc-url $(L1_RPC_URL) \
# 	--workdir .. --forge-cmd 'forge script --rpc-url $(L1_RPC_URL) \
# 	$(SCRIPT) --sig "sign(address[])" [] --sender $(SENDER)' --out ../validations/base-signer-rollback.json;

# .PHONY: execute-rollback
# execute-rollback:
# 	$(call MULTISIG_EXECUTE,$(SIGNATURES))
