PROJECT_DIR = $(network)/$(shell date +'%Y-%m-%d')-$(task)
MCM_SIGNERS_UPDATE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-signers-update
PROGRAM_UPGRADE_DIR = $(network)/$(shell date +'%Y-%m-%d')-mcm-program-upgrade

TEMPLATE_MCM_SIGNERS_UPDATE = setup-templates/template-mcm-signers-update
TEMPLATE_PROGRAM_UPGRADE = setup-templates/template-mcm-program-upgrade
TEMPLATE_GENERIC = setup-templates/template-mcm-generic

##
# Project Setup
##

# Run `make setup-mcm-task network=<network>`
setup-mcm-task:
	rm -rf $(TEMPLATE_GENERIC)/cache $(TEMPLATE_GENERIC)/lib $(TEMPLATE_GENERIC)/out
	cp -r $(TEMPLATE_GENERIC) $(PROJECT_DIR)

# Run `make setup-mcm-signers-update network=<network>`
setup-mcm-signers-update:
	rm -rf $(TEMPLATE_MCM_SIGNERS_UPDATE)/cache $(TEMPLATE_MCM_SIGNERS_UPDATE)/lib $(TEMPLATE_MCM_SIGNERS_UPDATE)/out
	cp -r $(TEMPLATE_MCM_SIGNERS_UPDATE) $(MCM_SIGNERS_UPDATE_DIR)

# Run `make setup-mcm-program-upgrade network=<network>`
setup-mcm-program-upgrade:
	rm -rf $(TEMPLATE_PROGRAM_UPGRADE)/cache $(TEMPLATE_PROGRAM_UPGRADE)/lib $(TEMPLATE_PROGRAM_UPGRADE)/out
	cp -r $(TEMPLATE_PROGRAM_UPGRADE) $(PROGRAM_UPGRADE_DIR)

##
# Dependencies
##

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base/eip712sign@v0.0.15

.PHONY: install-mcmctl
install-mcmctl:
	go install github.com/base/mcm-go/cmd/mcmctl@v0.1.2

.PHONY: deps
deps: install-mcmctl install-eip712sign

##
# MCM commands
##

ifndef MCM_IXS_OUTPUT
override MCM_IXS_OUTPUT = ixs.json
endif

ifndef MCM_PROPOSAL_OUTPUT
override MCM_PROPOSAL_OUTPUT = proposal.json
endif

.PHONY: mcm-print-authority
mcm-print-authority:
	mcmctl multisig print-authority \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)

.PHONY: mcm-print-config
mcm-print-config:
	mcmctl signers print-config \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)

.PHONY: mcm-proposal
mcm-proposal:
	mcmctl proposal create \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		--instructions $(MCM_IXS_OUTPUT) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-sign
mcm-sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --text -- \
	mcmctl proposal hash --proposal $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-init-signatures
mcm-init-signatures:
	mcmctl signatures init \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(MCM_PROPOSAL_OUTPUT) \
		--total $(MCM_SIGNATURES_COUNT)

.PHONY: mcm-append-signatures
mcm-append-signatures:
	mcmctl signatures append \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(MCM_PROPOSAL_OUTPUT) \
		--signatures $(MCM_SIGNATURES)

.PHONY: mcm-finalize-signatures
mcm-finalize-signatures:
	mcmctl signatures finalize \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-set-root
mcm-set-root:
	mcmctl proposal set-root \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-execute
mcm-execute:
	mcmctl proposal execute \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-all
mcm-all:
	make mcm-init-signatures
	make mcm-append-signatures
	make mcm-finalize-signatures
	make mcm-set-root
	make mcm-execute

