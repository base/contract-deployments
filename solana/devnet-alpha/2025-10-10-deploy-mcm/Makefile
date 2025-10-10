include ../.env
include .env

include ../../Makefile

.PHONY: mcm-clone
mcm-clone:
	rm -rf chainlink-ccip
	git clone --filter=blob:none $(MCM_REPO) chainlink-ccip
	cd chainlink-ccip && \
		git checkout $(MCM_AUDITED_COMMIT) && \
		git apply ../$(MCM_PROGRAM_PATCH)

.PHONY: mcm-deploy
mcm-deploy:
	cd chainlink-ccip/chains/solana/contracts && \
		anchor keys sync  && \
		anchor build -p mcm && \
		anchor deploy --provider.cluster $(CLUSTER) --provider.wallet $(WALLET) -p mcm

.PHONY: mcm-init
mcm-init:
	mcmctl multisig init \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--chain-id $(MCM_CHAIN_ID)

.PHONY: mcm-authority
mcm-authority:
	mcmctl multisig print-authority \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)

.PHONY: mcm-init-signers
mcm-init-signers:
	mcmctl signers init \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--total $(MCM_SIGNER_COUNT)
	mcmctl signers append \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--signers $(MCM_SIGNERS)
	mcmctl signers finalize \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)
	mcmctl signers set-config \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--signer-groups $(MCM_SIGNER_GROUPS) \
		--group-quorums $(MCM_GROUP_QUORUMS) \
		--group-parents $(MCM_GROUP_PARENTS)
	mcmctl signers print-config \
		--rpc-url $(SOL_RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--pretty

.PHONY: mcm-accept-ownership-proposal
mcm-accept-ownership-proposal:
	go run main.go \
		--ixs-output $(MCM_IXS_OUTPUT) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID)
	make mcm-proposal
	rm $(MCM_IXS_OUTPUT)

# Internal target - do not run manually
.PHONY: mcm-accept-ownership
mcm-accept-ownership:
	make mcm-init-signatures
	make mcm-append-signatures
	make mcm-finalize-signatures
	make mcm-set-root
	make mcm-execute

.PHONY: mcm-transfer-ownership
mcm-transfer-ownership:
	mcmctl ownership transfer \
		--rpc-url $(SOL_RPC_URL) \
		--ws-url $(SOL_WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MCM_MULTISIG_ID) \
		--proposed-owner $(MCM_AUTHORITY)
	make mcm-accept-ownership
	make mcm-print-config

.PHONY: mcm-transfer-upgrade-authority
mcm-transfer-upgrade-authority:
	solana program set-upgrade-authority $(MCM_PROGRAM_ID) \
		--url $(SOL_RPC_URL) \
		--new-upgrade-authority $(MCM_AUTHORITY) \
		--skip-new-upgrade-authority-signer-check
	solana program show $(MCM_PROGRAM_ID) \
		--url $(SOL_RPC_URL)
