PROJECT_DIR = $(network)/$(shell date +'%Y-%m-%d')-$(task)
GAS_INCREASE_DIR = $(network)/$(shell date +'%Y-%m-%d')-increase-gas-limit
FAULT_PROOF_UPGRADE_DIR = $(network)/$(shell date +'%Y-%m-%d')-upgrade-fault-proofs
SAFE_MANAGEMENT_DIR = $(network)/$(shell date +'%Y-%m-%d')-safe-swap-owner
FUNDING_DIR = $(network)/$(shell date +'%Y-%m-%d')-funding

TEMPLATE_GENERIC = setup-templates/template-generic
TEMPLATE_GAS_INCREASE = setup-templates/template-gas-increase
TEMPLATE_UPGRADE_FAULT_PROOFS = setup-templates/template-upgrade-fault-proofs
TEMPLATE_SAFE_MANAGEMENT = setup-templates/template-safe-management
TEMPLATE_FUNDING = setup-templates/template-funding

ifndef $(GOPATH)
    GOPATH=$(shell go env GOPATH)
    export GOPATH
endif

.PHONY: install-foundry
install-foundry:
	curl -L https://foundry.paradigm.xyz | bash
	~/.foundry/bin/foundryup --commit $(FOUNDRY_COMMIT)

##
# Project Setup
##
# Run `make setup-task network=<network> task=<task>`
setup-task:
	rm -rf $(TEMPLATE_GENERIC)/cache $(TEMPLATE_GENERIC)/lib $(TEMPLATE_GENERIC)/out
	cp -r $(TEMPLATE_GENERIC) $(PROJECT_DIR)

# Run `make setup-gas-increase network=<network>`
setup-gas-increase:
	rm -rf $(TEMPLATE_GAS_INCREASE)/cache $(TEMPLATE_GAS_INCREASE)/lib $(TEMPLATE_GAS_INCREASE)/out
	cp -r $(TEMPLATE_GAS_INCREASE) $(GAS_INCREASE_DIR)

# Run `make setup-upgrade-fault-proofs network=<network>`
setup-upgrade-fault-proofs:
	cp -r $(TEMPLATE_UPGRADE_FAULT_PROOFS) $(FAULT_PROOF_UPGRADE_DIR)

# Run `make setup-safe-management network=<network>`
setup-safe-management:
	rm -rf $(TEMPLATE_SAFE_MANAGEMENT)/cache $(TEMPLATE_SAFE_MANAGEMENT)/lib $(TEMPLATE_SAFE_MANAGEMENT)/out
	cp -r $(TEMPLATE_SAFE_MANAGEMENT) $(SAFE_MANAGEMENT_DIR)

# Run `make setup-funding network=<network>`
setup-funding:
	rm -rf $(TEMPLATE_FUNDING)/cache $(TEMPLATE_FUNDING)/lib $(TEMPLATE_FUNDING)/out
	cp -r $(TEMPLATE_FUNDING) $(FUNDING_DIR)

##
# Solidity Setup
##
.PHONY: deps
deps: install-eip712sign clean-lib forge-deps checkout-op-commit checkout-base-contracts-commit

.PHONY: install-eip712sign
install-eip712sign:
	go install github.com/base/eip712sign@v0.0.11

.PHONY: clean-lib
clean-lib:
	rm -rf lib

.PHONY: forge-deps
forge-deps:
	forge install --no-git github.com/foundry-rs/forge-std \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 \
		github.com/Vectorized/solady@796d4676c7683aa801e8e224ea51e944e3153e6d \
		github.com/ethereum-optimism/lib-keccak@3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9

.PHONY: install
install: install-tool-deps install-state-diff

.PHONY: install-tool-deps
install-tool-deps:
	cd validation-tool-interface && npm install

.PHONY: install-state-diff
install-state-diff:
	rm -rf go-simulator
	git clone https://github.com/jackchuma/state-diff.git go-simulator
	cd go-simulator && git checkout 5c5bae2d54fd9ef55880d87e9b648c4cbd4cb42a
	cd go-simulator && go mod download
	cd go-simulator && go build -o state-diff .

.PHONY: clean-install
clean-install: clean-tool-deps clean-state-diff install

.PHONY: clean-tool-deps
clean-tool-deps:
	@echo "Cleaning tool dependencies..."
	rm -rf validation-tool-interface/node_modules
	rm -rf validation-tool-interface/.next

.PHONY: clean-state-diff
clean-state-diff:
	@echo "Cleaning state-diff installation..."
	rm -rf go-simulator

# Default port (can be overridden with PORT=xxxx make validation)
PORT ?= 1234

.PHONY: validation
validation: install
	cd validation-tool-interface && npm run build
	@echo "Starting server on port $(PORT) and opening browser..."
	@cd validation-tool-interface && npm run start -- -p $(PORT) & \
	SERVER_PID=$$!; \
	sleep 3; \
	open http://localhost:$(PORT); \
	echo "Browser opened. Server running on port $(PORT) with PID $$SERVER_PID. Press Ctrl+C to stop."; \
	wait $$SERVER_PID

.PHONY: checkout-op-commit
checkout-op-commit:
	[ -n "$(OP_COMMIT)" ] || (echo "OP_COMMIT must be set in .env" && exit 1)
	rm -rf lib/optimism
	mkdir -p lib/optimism
	cd lib/optimism; \
	git init; \
	git remote add origin https://github.com/ethereum-optimism/optimism.git; \
	git fetch --depth=1 origin $(OP_COMMIT); \
	git reset --hard FETCH_HEAD

.PHONY: checkout-base-contracts-commit
checkout-base-contracts-commit:
	[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	rm -rf lib/base-contracts
	mkdir -p lib/base-contracts
	cd lib/base-contracts; \
	git init; \
	git remote add origin https://github.com/base/contracts.git; \
	git fetch --depth=1 origin $(BASE_CONTRACTS_COMMIT); \
	git reset --hard FETCH_HEAD

##
# Solidity Testing
##
.PHONY: solidity-test
solidity-test:
	forge test --ffi -vvv
