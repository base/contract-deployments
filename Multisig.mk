# ---------- Common fragments ----------

LEDGER_HD_PATH = "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"

empty :=
space := $(empty) $(empty)
comma := ,

# Join a whitespace-separated list with ", " and normalize whitespace
comma_join = $(subst $(space),$(comma) ,$(strip $(foreach w,$(1),$(w))))

# Validation helper for required variables
require_vars = $(foreach _var,$(2),$(if $(strip $($(_var))),,$(error $(1): required variable $(_var) is not defined)))

# ---------- Procedures ----------

# MULTISIG_SIGN: $(1)=address list (space-separated)
define MULTISIG_SIGN
$(call require_vars,MULTISIG_SIGN,LEDGER_ACCOUNT RPC_URL SCRIPT_NAME)
	$(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) -- \
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "sign(address[])" "[$(call comma_join,$(1))]"
endef

# MULTISIG_APPROVE: $(1)=address list (space-separated), $(2)=signatures (e.g., 0x or $(SIGNATURES))
define MULTISIG_APPROVE
$(call require_vars,MULTISIG_APPROVE,LEDGER_ACCOUNT RPC_URL SCRIPT_NAME)
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "approve(address[],bytes)" "[$(call comma_join,$(1))]" $(2) \
	--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
endef

# MULTISIG_EXECUTE: $(1)=signatures for run(bytes) (e.g., 0x or $(SIGNATURES))
define MULTISIG_EXECUTE
$(call require_vars,MULTISIG_EXECUTE,LEDGER_ACCOUNT RPC_URL SCRIPT_NAME)
	forge script --rpc-url $(RPC_URL) $(SCRIPT_NAME) \
	--sig "run(bytes)" $(1) \
	--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
endef