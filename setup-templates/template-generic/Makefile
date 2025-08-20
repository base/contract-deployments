include ../../Makefile
include ../.env
include .env

# ---------- Common fragments ----------

LEDGER_HD_PATH := "m/44'/60'/$(LEDGER_ACCOUNT)'/0/0"
EIP712SIGN     := $(GOPATH)/bin/eip712sign --ledger --hd-paths $(LEDGER_HD_PATH) --
FORGE_BASE     := forge script --rpc-url $(L1_RPC_URL) CounterMultisigScript

empty :=
space := $(empty) $(empty)
comma := ,

# Join a space-separated list with ", "
comma_join = $(subst $(space),$(comma) ,$(strip $(1)))

# ---------- Procedures ----------

# $(1) address list (space-separated)
define SIGN
	$(EIP712SIGN) \
	$(FORGE_BASE) \
	--sig "sign(address[])" "[$(call comma_join,$(1))]"
endef

# $(1) address list (space-separated)
# $(2) signatures (e.g., 0x or $(SIGNATURES))
define APPROVE
	$(FORGE_BASE) \
	--sig "approve(address[],bytes)" "[$(call comma_join,$(1))]" $(2) \
	--ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
endef

# $(1) signatures for run(bytes)
define EXECUTE
	$(FORGE_BASE) \
	--sig "run(bytes)" $(1) --ledger --hd-paths $(LEDGER_HD_PATH) --broadcast -vvvv
endef

# ---------- Targets ----------

#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                     L2-0                    │       │                    L2-1                     │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │
#                          └───────────────────────┬─────────────────────────────┘
#                                                  ▼
#                             ┌─────────────────────────────────────────────┐                                    ┌─────────────────────────────────────────────┐
#                             │                    L1-0                     │                                    │                    L1-1                     │
#                             └─────────────────────┬───────────────────────┘                                    └─────────────────────┬───────────────────────┘
#                                                   │                                                                                  │
#                                                   └──────────────────────────────────────┬───────────────────────────────────────────┘
#                                                                                          ▼
#                                            		               ┌─────────────────────────────────────────────┐
#                                            		               │                   OWNER_SAFE                │
#                                            		               └─────────────────────────────────────────────┘


# L2-0
.PHONY: sign-l2-0
sign-l2-0:
	$(call SIGN,$(L2_0) $(L1_0))

.PHONY: approve-l2-0
approve-l2-0:
	$(call APPROVE,$(L2_0) $(L1_0),$(SIGNATURES))


# L2-1
.PHONY: sign-l2-1
sign-l2-1:
	$(call SIGN,$(L2_0) $(L2_1))

.PHONY: approve-l2-1
approve-l2-1:
	$(call APPROVE,$(L2_0) $(L2_1),$(SIGNATURES))


# L1-0
.PHONY: approve-l1-0
approve-l1-0:
	$(call APPROVE,$(L1_0),0x)


# L1-1
.PHONY: sign-l1-1
sign-l1-1:
	$(call SIGN,$(L1_1))

.PHONY: approve-l1-1
approve-l1-1:
	$(call APPROVE,$(L1_1),$(SIGNATURES))

# Execute
.PHONY: execute
execute:
	$(call EXECUTE,0x)