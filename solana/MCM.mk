##
# MCM Commands
# This file contains all Multi-Chain Management (MCM) related commands
##

ifndef MCM_IXS_OUTPUT
override MCM_IXS_OUTPUT = ixs.json
endif

ifndef MCM_PROPOSAL_OUTPUT
override MCM_PROPOSAL_OUTPUT = proposal.json
endif

##
# Read-only commands (no transaction wrapping needed)
##

.PHONY: mcm-multisig-print-authority
mcm-multisig-print-authority:
	mcmctl multisig print-authority \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)

.PHONY: mcm-signers-print-config
mcm-signers-print-config:
	mcmctl signers print-config \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--pretty

.PHONY: mcm-proposal-create
mcm-proposal-create:
	mcmctl proposal create \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		--instructions $(MCM_IXS_OUTPUT) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-proposal-hash
mcm-proposal-hash:
	mcmctl proposal hash --proposal $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-sign
mcm-sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --text -- \
	make mcm-proposal-hash

##
# Atomic commands with transaction confirmation
##

.PHONY: mcm-multisig-init
mcm-multisig-init:
	make sol-confirm-cmd \
		cmd="mcmctl multisig init \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID) \
			--chain-id $(MCM_CHAIN_ID)" \
		output=artifacts/mcm-multisig-init.json

.PHONY: mcm-signers-init
mcm-signers-init:
	make sol-confirm-cmd \
		cmd="mcmctl signers init \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID) \
			--total $(MCM_SIGNER_COUNT)" \
		output=artifacts/mcm-signers-init.json

.PHONY: mcm-signers-append
mcm-signers-append:
	make sol-confirm-cmd \
		cmd="mcmctl signers append \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID) \
			--signers $(MCM_SIGNERS)" \
		output=artifacts/mcm-signers-append.json

.PHONY: mcm-signers-finalize
mcm-signers-finalize:
	make sol-confirm-cmd \
		cmd="mcmctl signers finalize \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID)" \
		output=artifacts/mcm-signers-finalize.json

.PHONY: mcm-signers-clear
mcm-signers-clear:
	make sol-confirm-cmd \
		cmd="mcmctl signers clear \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID)" \
		output=artifacts/mcm-signers-clear.json

.PHONY: mcm-signers-set-config
mcm-signers-set-config:
	make sol-confirm-cmd \
		cmd="mcmctl signers set-config \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID) \
			--signer-groups $(MCM_SIGNER_GROUPS) \
			--group-quorums $(MCM_GROUP_QUORUMS) \
			--group-parents $(MCM_GROUP_PARENTS) \
			$(if $(filter true,$(MCM_CLEAR_ROOT)),--clear-root)" \
		output=artifacts/mcm-signers-set-config.json

.PHONY: mcm-signatures-init
mcm-signatures-init:
	make sol-confirm-cmd \
		cmd="mcmctl signatures init \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT) \
			--total $(MCM_SIGNATURES_COUNT)" \
		output=artifacts/mcm-signatures-init.json

.PHONY: mcm-signatures-append
mcm-signatures-append:
	make sol-confirm-cmd \
		cmd="mcmctl signatures append \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT) \
			--signatures $(MCM_SIGNATURES)" \
		output=artifacts/mcm-signatures-append.json

.PHONY: mcm-signatures-finalize
mcm-signatures-finalize:
	make sol-confirm-cmd \
		cmd="mcmctl signatures finalize \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT)" \
		output=artifacts/mcm-signatures-finalize.json

.PHONY: mcm-signatures-clear
mcm-signatures-clear:
	make sol-confirm-cmd \
		cmd="mcmctl signatures clear \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT)" \
		output=artifacts/mcm-signatures-clear.json

.PHONY: mcm-ownership-transfer
mcm-ownership-transfer:
	make sol-confirm-cmd \
		cmd="mcmctl ownership transfer \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID) \
			--proposed-owner $(MCM_PROPOSED_OWNER)" \
		output=artifacts/mcm-ownership-transfer.json

.PHONY: mcm-ownership-accept
mcm-ownership-accept:
	make sol-confirm-cmd \
		cmd="mcmctl ownership accept \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--multisig-id $(MCM_MULTISIG_ID)" \
		output=artifacts/mcm-ownership-accept.json

.PHONY: mcm-proposal-set-root
mcm-proposal-set-root:
	make sol-confirm-cmd \
		cmd="mcmctl proposal set-root \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT)" \
		output=artifacts/mcm-proposal-set-root.json

.PHONY: mcm-proposal-execute
mcm-proposal-execute:
	make sol-confirm-cmd \
		cmd="mcmctl proposal execute \
			--rpc-url $(SOL_RPC_URL) \
			--ws-url $(SOL_WS_URL) \
			--mcm-program-id $(MCM_PROGRAM_ID) \
			--authority $(AUTHORITY) \
			--proposal $(MCM_PROPOSAL_OUTPUT) \
			$(if $(MCM_START_INDEX),--start-index $(MCM_START_INDEX)) \
			$(if $(MCM_OPERATION_COUNT),--operation-count $(MCM_OPERATION_COUNT))" \
		output=artifacts/mcm-proposal-execute.json

##
# Proposal creation commands (read-only, create proposal files)
##

.PHONY: mcm-proposal-accept-ownership
mcm-proposal-accept-ownership:
	mcmctl proposal mcm accept-ownership \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT)

.PHONY: mcm-proposal-update-signers
mcm-proposal-update-signers:
	mcmctl proposal mcm update-signers \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT) \
		--new-signers $(MCM_NEW_SIGNERS) \
		--signer-groups $(MCM_SIGNER_GROUPS) \
		--group-quorums $(MCM_GROUP_QUORUMS) \
		--group-parents $(MCM_GROUP_PARENTS) \
		$(if $(filter true,$(MCM_CLEAR_ROOT)),--clear-root)

.PHONY: mcm-proposal-bridge-pause
mcm-proposal-bridge-pause:
	mcmctl proposal bridge pause \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT) \
		--bridge-program-id $(BRIDGE_PROGRAM_ID) \
		--bridge $(BRIDGE_ACCOUNT) \
		--guardian $(GUARDIAN) \
		$(if $(filter true,$(PAUSED)),--paused)

.PHONY: mcm-proposal-loader-v3-upgrade
mcm-proposal-loader-v3-upgrade:
	mcmctl proposal loader-v3 upgrade \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT) \
		--program $(PROGRAM) \
		--buffer $(BUFFER) \
		--spill $(SPILL)

.PHONY: mcm-proposal-loader-v3-set-authority
mcm-proposal-loader-v3-set-authority:
	mcmctl proposal loader-v3 set-authority \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--valid-until $(MCM_VALID_UNTIL) \
		$(if $(filter true,$(MCM_OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(MCM_PROPOSAL_OUTPUT) \
		--account $(LOADER_ACCOUNT) \
		--new-authority $(LOADER_NEW_AUTHORITY)

##
# Orchestrated commands
##

.PHONY: mcm-signers-all
mcm-signers-all:
	make mcm-signers-init
	make mcm-signers-append
	make mcm-signers-finalize
	make mcm-signers-set-config
	make mcm-signers-print-config

.PHONY: mcm-signatures-all
mcm-signatures-all:
	make mcm-signatures-init
	make mcm-signatures-append
	make mcm-signatures-finalize

.PHONY: mcm-proposal-all
mcm-proposal-all:
	make mcm-proposal-set-root
	make mcm-proposal-execute

.PHONY: mcm-all
mcm-all:
	make mcm-signatures-all
	make mcm-proposal-all
