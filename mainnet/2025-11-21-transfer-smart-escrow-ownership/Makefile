include ../../Makefile
include ../../Multisig.mk

include ../.env
include .env

ifndef LEDGER_ACCOUNT
override LEDGER_ACCOUNT = 0
endif

L2_RPC_URL=https://mainnet.optimism.io
RPC_URL = $(L2_RPC_URL)
SCRIPT_NAME = InitOwnershipTransfer

# OWNER_SAFE/
# ├── CB_SIGNER_SAFE_ADDR/
# │   └── Signers
# └── OP_SIGNER_SAFE_ADDR/
#     └── Signers

.PHONY: gen-validation-cb
gen-validation-cb: checkout-signer-tool run-script-cb

.PHONY: run-script-cb
run-script-cb:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--ledger-id $(LEDGER_ACCOUNT) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(CB_SIGNER_SAFE_ADDR)]" --sender 0x6CD3850756b7894774Ab715D136F9dD02837De50' --out ../validations/cb-signer.json;

.PHONY: gen-validation-op
gen-validation-op: checkout-signer-tool run-script-op

.PHONY: run-script-op
run-script-op:
	cd $(SIGNER_TOOL_PATH); \
	npm ci; \
	bun run scripts/genValidationFile.ts --rpc-url $(RPC_URL) \
	--ledger-id $(LEDGER_ACCOUNT) \
	--workdir .. --forge-cmd 'forge script --rpc-url $(RPC_URL) \
	$(SCRIPT_NAME) --sig "sign(address[])" "[$(OP_SIGNER_SAFE_ADDR)]" --sender 0x4d494C5F61b60752D3A10062276a0eFC22596151' --out ../validations/op-signer.json;

.PHONY: approve-cb
approve-cb:
	$(call MULTISIG_APPROVE,$(CB_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: approve-op
approve-op:
	$(call MULTISIG_APPROVE,$(OP_SIGNER_SAFE_ADDR),$(SIGNATURES))

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,0x)
