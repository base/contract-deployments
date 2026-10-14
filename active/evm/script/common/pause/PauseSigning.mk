ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK must be set on the command line: make TASK_NETWORK=<network> <target>)
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK must not be empty)
endif

PAUSE_SIGNING_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: deps-pause sign-pause
deps-pause: bootstrap-mise
	@set -eu; \
	goroot=$$($(MISE_EXEC) go env GOROOT); \
	[ -n "$$goroot" ] || { echo "Could not resolve mise Go GOROOT" >&2; exit 1; }; \
	GOBIN="$$goroot/bin" $(MISE_EXEC) go install github.com/base/eip712sign@v0.0.11

sign-pause: deps-pause
	@TASK_NETWORK="$(TASK_NETWORK)" L1_RPC_URL="$(L1_RPC_URL)" \
		INCIDENT_MULTISIG="$(INCIDENT_MULTISIG)" SYSTEM_CONFIG="$(SYSTEM_CONFIG)" \
		LEDGER_ACCOUNT="$(LEDGER_ACCOUNT)" MISE="$(MISE)" \
		bash "$(PAUSE_SIGNING_DIR)sign-pause.sh"
