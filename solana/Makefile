MCM_SIGNERS_UPDATE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-signers-update
PROGRAM_UPGRADE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-program-upgrade
SET_PAUSE_BRIDGE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-set-pause-bridge
SET_PARTNER_THRESHOLD_BRIDGE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-set-partner-threshold-bridge

TEMPLATE_MCM_SIGNERS_UPDATE = setup-templates/template-mcm-signers-update
TEMPLATE_PROGRAM_UPGRADE = setup-templates/template-mcm-program-upgrade
TEMPLATE_SET_PAUSE_BRIDGE = setup-templates/template-mcm-set-pause-bridge
TEMPLATE_SET_PARTNER_THRESHOLD_BRIDGE = setup-templates/template-mcm-set-partner-threshold-bridge

##
# Project Setup
##

# Run `make setup-mcm-signers-update network=<network>`
setup-mcm-signers-update:
	rm -rf $(TEMPLATE_MCM_SIGNERS_UPDATE)/cache $(TEMPLATE_MCM_SIGNERS_UPDATE)/lib $(TEMPLATE_MCM_SIGNERS_UPDATE)/out
	cp -r $(TEMPLATE_MCM_SIGNERS_UPDATE) $(MCM_SIGNERS_UPDATE_DIR)

# Run `make setup-mcm-program-upgrade network=<network>`
setup-mcm-program-upgrade:
	rm -rf $(TEMPLATE_PROGRAM_UPGRADE)/cache $(TEMPLATE_PROGRAM_UPGRADE)/lib $(TEMPLATE_PROGRAM_UPGRADE)/out
	cp -r $(TEMPLATE_PROGRAM_UPGRADE) $(PROGRAM_UPGRADE_DIR)

# Run `make setup-mcm-set-pause-bridge network=<network>`
setup-mcm-set-pause-bridge:
	rm -rf $(TEMPLATE_SET_PAUSE_BRIDGE)/cache $(TEMPLATE_SET_PAUSE_BRIDGE)/lib $(TEMPLATE_SET_PAUSE_BRIDGE)/out
	cp -r $(TEMPLATE_SET_PAUSE_BRIDGE) $(SET_PAUSE_BRIDGE_DIR)

# Run `make setup-mcm-set-partner-threshold-bridge network=<network>`
setup-mcm-set-partner-threshold-bridge:
	rm -rf $(TEMPLATE_SET_PARTNER_THRESHOLD_BRIDGE)/cache $(TEMPLATE_SET_PARTNER_THRESHOLD_BRIDGE)/lib $(TEMPLATE_SET_PARTNER_THRESHOLD_BRIDGE)/out
	cp -r $(TEMPLATE_SET_PARTNER_THRESHOLD_BRIDGE) $(SET_PARTNER_THRESHOLD_BRIDGE_DIR)

##
# Dependencies
##

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base/eip712sign@v0.0.15

.PHONY: install-mcmctl
install-mcmctl:
	go install github.com/base/mcm-go/cmd/mcmctl@v0.3.6

.PHONY: deps
deps: install-mcmctl install-eip712sign

##
# MCM commands - imported from MCM.mk
##

include $(dir $(lastword $(MAKEFILE_LIST)))MCM.mk

##
# Solana Utils
##

# Run `make sol-confirm-cmd cmd=<command> output=<output-file>`
# Captures signature from command output and confirms it
.PHONY: sol-confirm-cmd
sol-confirm-cmd:
	@OUTPUT=$$($(cmd) 2>&1 | tee /dev/tty); \
	SIG=$$(echo "$$OUTPUT" | grep -oE '[1-9A-HJ-NP-Za-km-z]{87,88}' | tail -1); \
	if [ -n "$$SIG" ]; then \
		echo ""; \
		$(MAKE) sol-confirm SIG=$$SIG output=$(output); \
		echo "Transaction artifacts written to $(output)"; \
	else \
		echo "ERROR: No signature found"; \
		exit 1; \
	fi

# Run `make sol-confirm SIG=<signature> output=<output-file>`
# Confirms a signature and saves the result to a JSON file
.PHONY: sol-confirm
sol-confirm:
	@echo "==> Confirming signature: $$SIG"; \
	mkdir -p $(dir $(output)); \
	solana confirm $$SIG -v --output json --url $(SOL_RPC_URL) >> $(output)

##
# Solana Native Commands
##

.PHONY: sol-program-show
sol-program-show:
	solana program show $(SOL_PROGRAM_ID) --url $(SOL_RPC_URL)

.PHONY: sol-transfer
sol-transfer: output ?= artifacts/sol-transfer.json
sol-transfer:
	make sol-confirm-cmd \
		cmd="solana transfer $(SOL_RECIPIENT) $(SOL_AMOUNT) \
			--url $(SOL_RPC_URL) \
			--fee-payer $(AUTHORITY) \
			--allow-unfunded-recipient" \
		output=$(output)

# This command does not output the signature, so we cannot use make sol-confirm-cmd
.PHONY: sol-program-set-upgrade-authority
sol-program-set-upgrade-authority:
	solana program set-upgrade-authority $(SOL_PROGRAM_ID) \
	--url $(SOL_RPC_URL) \
	--new-upgrade-authority $(NEW_UPGRADE_AUTHORITY) \
	--skip-new-upgrade-authority-signer-check

# This command does not output the signature, so we cannot use make sol-confirm-cmd
.PHONY: sol-write-buffer
sol-write-buffer:
	solana program write-buffer $(PROGRAM_BINARY) \
	--url $(SOL_RPC_URL)

# This command does not output the signature, so we cannot use make sol-confirm-cmd
.PHONY: sol-set-buffer-authority
sol-set-buffer-authority:
	solana program set-buffer-authority $(BUFFER) \
	--new-buffer-authority $(NEW_BUFFER_AUTHORITY) \
	--url $(SOL_RPC_URL)"
