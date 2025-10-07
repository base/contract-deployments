include .env.example

.PHONY: install-mcmctl
install-mcmctl:
	go install github.com/base/mcm-go/cmd/mcmctl@dd40ca6111592532cdade4f2867e65433c8a0564

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base/eip712sign@v0.0.15

.PHONY: deps
deps: install-mcmctl install-eip712sign

.PHONY: write-buffer
write-buffer:
	solana program write-buffer $(PROGRAM_BINARY) --url $(RPC_URL)

.PHONY: print-authority
print-authority:
	mcmctl multisig print-authority --program-id $(MCM_PROGRAM_ID) --multisig-id $(MULTISIG_ID)

.PHONY: set-buffer-authority
set-buffer-authority:
	solana program set-buffer-authority $(BUFFER) \
		--new-buffer-authority $(MCM_AUTHORITY) \
		--url $(RPC_URL)

.PHONY: ixs
ixs:
	go run main.go \
		--rpc-url $(RPC_URL) \
		--program $(PROGRAM) \
		--buffer $(BUFFER) \
		--spill $(SPILL) \
		--output $(IXS_OUTPUT)

.PHONY: proposal
proposal:
	mcmctl proposal create \
		--rpc-url $(RPC_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--multisig-id $(MULTISIG_ID) \
		--valid-until $(VALID_UNTIL) \
		--instructions $(IXS_OUTPUT) \
		$(if $(filter true,$(OVERRIDE_PREVIOUS_ROOT)),--override-previous-root) \
		--output $(PROPOSAL_OUTPUT)

.PHONY: sign
sign:
	$(GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0" --text -- \
	mcmctl proposal hash --proposal $(PROPOSAL_OUTPUT)

.PHONY: init-signatures
init-signatures:
	mcmctl signatures init \
		--rpc-url $(RPC_URL) \
		--ws-url $(WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(PROPOSAL_OUTPUT) \
		--total $(SIGNATURES_COUNT)

.PHONY: append-signatures
append-signatures:
	mcmctl signatures append \
		--rpc-url $(RPC_URL) \
		--ws-url $(WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(PROPOSAL_OUTPUT) \
		--signatures $(SIGNATURES)

.PHONY: finalize-signatures
finalize-signatures:
	mcmctl signatures finalize \
		--rpc-url $(RPC_URL) \
		--ws-url $(WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(PROPOSAL_OUTPUT)

.PHONY: set-root
set-root:
	mcmctl proposal set-root \
		--rpc-url $(RPC_URL) \
		--ws-url $(WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(PROPOSAL_OUTPUT)

.PHONY: execute
execute:
	mcmctl proposal execute \
		--rpc-url $(RPC_URL) \
		--ws-url $(WS_URL) \
		--mcm-program-id $(MCM_PROGRAM_ID) \
		--proposal $(PROPOSAL_OUTPUT)
