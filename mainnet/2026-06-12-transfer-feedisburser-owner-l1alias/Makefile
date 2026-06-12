DEPS_TARGETS = task-deps

include ../../Makefile
include ../../Multisig.mk
include ../.env
include .env

RPC_URL = $(L1_RPC_URL)
SCRIPT_NAME = TransferFeeDisburserOwnership

define INSTALL_TASK_DEP
	rm -rf lib/$(1)
	mkdir -p lib/$(1)
	cd lib/$(1); \
	git init; \
	git remote add origin https://github.com/$(2).git; \
	git fetch --depth=1 origin $(3); \
	git checkout --detach FETCH_HEAD; \
	rm -rf .git
endef

.PHONY: task-deps
task-deps: bootstrap-mise install-eip712sign clean-lib task-forge-deps clone-oz-upgradeable task-base-contracts

.PHONY: task-forge-deps
task-forge-deps:
	$(call INSTALL_TASK_DEP,forge-std,foundry-rs/forge-std,0844d7e1fc5e60d77b68e469bff60265f236c398)
	$(call INSTALL_TASK_DEP,openzeppelin-contracts,OpenZeppelin/openzeppelin-contracts,v4.9.3)
	$(call INSTALL_TASK_DEP,solmate,rari-capital/solmate,8f9b23f8838670afda0fd8983f2c41e8037ae6bc)
	$(call INSTALL_TASK_DEP,clones-with-immutable-args,Saw-mon-and-Natalie/clones-with-immutable-args,105efee1b9127ed7f6fedf139e1fc796ce8791f2)
	$(call INSTALL_TASK_DEP,solady,Vectorized/solady,502cc1ea718e6fa73b380635ee0868b0740595f0)
	$(call INSTALL_TASK_DEP,lib-keccak,ethereum-optimism/lib-keccak,3b1e7bbb4cc23e9228097cfebe42aedaf3b8f2b9)

.PHONY: task-base-contracts
task-base-contracts:
	[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	$(call INSTALL_TASK_DEP,contracts,base/contracts,$(BASE_CONTRACTS_COMMIT))

.PHONY: gen-validation
gen-validation: deps-signer-tool
	$(call GEN_VALIDATION,$(SCRIPT_NAME),,$(SENDER),base-signer.json,)

.PHONY: execute
execute:
	$(call MULTISIG_EXECUTE,$(SIGNATURES))
