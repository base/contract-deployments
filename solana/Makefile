UPDATE_MCM_SIGNERS_DIR = $(network)/$(shell date +'%Y-%m-%d')-update-mcm-signers
UPGRADE_BRIDGE_PROGRAM_DIR = $(network)/$(shell date +'%Y-%m-%d')-upgrade-bridge-program
SET_PAUSE_BRIDGE_DIR = $(network)/$(shell date +'%Y-%m-%d')-set-pause-bridge

TEMPLATE_UPDATE_MCM_SIGNERS = setup-templates/template-update-mcm-signers
TEMPLATE_UPGRADE_BRIDGE_PROGRAM = setup-templates/template-upgrade-bridge-program
TEMPLATE_SET_PAUSE_BRIDGE = setup-templates/template-set-pause-bridge

##
# Project Setup
##

# Run `make setup-update-mcm-signers network=<network>`
setup-update-mcm-signers:
	rm -rf $(TEMPLATE_UPDATE_MCM_SIGNERS)/cache $(TEMPLATE_UPDATE_MCM_SIGNERS)/lib $(TEMPLATE_UPDATE_MCM_SIGNERS)/out
	cp -r $(TEMPLATE_UPDATE_MCM_SIGNERS) $(UPDATE_MCM_SIGNERS_DIR)

# Run `make setup-upgrade-bridge-program network=<network>`
setup-upgrade-bridge-program:
	rm -rf $(TEMPLATE_UPGRADE_BRIDGE_PROGRAM)/cache $(TEMPLATE_UPGRADE_BRIDGE_PROGRAM)/lib $(TEMPLATE_UPGRADE_BRIDGE_PROGRAM)/out
	cp -r $(TEMPLATE_UPGRADE_BRIDGE_PROGRAM) $(UPGRADE_BRIDGE_PROGRAM_DIR)

# Run `make setup-set-pause-bridge network=<network>`
setup-set-pause-bridge:
	rm -rf $(TEMPLATE_SET_PAUSE_BRIDGE)/cache $(TEMPLATE_SET_PAUSE_BRIDGE)/lib $(TEMPLATE_SET_PAUSE_BRIDGE)/out
	cp -r $(TEMPLATE_SET_PAUSE_BRIDGE) $(SET_PAUSE_BRIDGE_DIR)

##
# Dependencies
##

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base/eip712sign@v0.0.15

.PHONY: install-mcmctl
install-mcmctl:
	go install github.com/base/mcm-go/cmd/mcmctl@66ad0d9e28ecc1ef0b3b1504bdc5d40da413b678

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
	solana confirm $$SIG -v --output json --url $(SOL_RPC_URL) > $(output)

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
	--url $(SOL_RPC_URL)
