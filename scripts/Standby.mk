ifneq ($(origin TASK_NETWORK),command line)
$(error TASK_NETWORK is required on the command line, e.g. make TASK_NETWORK=<network> $(MAKECMDGOALS))
endif

identifier_chars := a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 -
strip_identifier_chars = $(if $(strip $(2)),$(call strip_identifier_chars,$(subst $(firstword $(2)),,$(1)),$(wordlist 2,$(words $(2)),$(2))),$(1))
ifneq ($(call strip_identifier_chars,$(TASK_NETWORK),$(identifier_chars)),)
$(error invalid TASK_NETWORK)
endif
ifeq ($(strip $(TASK_NETWORK)),)
$(error invalid TASK_NETWORK)
endif
ifneq ($(words $(TASK_NETWORK)),1)
$(error invalid TASK_NETWORK)
endif

ifneq ($(filter archive-task,$(MAKECMDGOALS)),)
date_chars := 0 1 2 3 4 5 6 7 8 9 -
ifneq ($(call strip_identifier_chars,$(TASK_DATE),$(date_chars)),)
$(error invalid TASK_DATE)
endif
ifeq ($(strip $(TASK_DATE)),)
$(error invalid TASK_DATE: use TASK_DATE=YYYY-MM-DD)
endif
ifneq ($(words $(TASK_DATE)),1)
$(error invalid TASK_DATE)
endif
endif

.DEFAULT_GOAL := prepare

STANDBY_TASK_DIR := $(CURDIR)
include $(dir $(lastword $(MAKEFILE_LIST)))../Makefile
include $(REPO_ROOT)/Multisig.mk

PROJECT_DIR := $(REPO_ROOT)/active/evm
ifneq ($(wildcard $(CURDIR)/foundry.toml),)
PROJECT_DIR := $(CURDIR)
endif

NETWORK_ENV := $(REPO_ROOT)/config/$(TASK_NETWORK).env
ifneq ($(wildcard config/*/network.env),)
$(error network.env is reserved for the archive snapshot)
endif
include $(NETWORK_ENV)
include config/$(TASK_NETWORK)/.env

SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(CURDIR)/config/$(TASK_NETWORK)/validations
TASK_ORIGIN_DIR := $(CURDIR)/config/$(TASK_NETWORK)
SIGNATURE_DIR := $(CURDIR)/signatures/$(TASK_NETWORK)
RPC_URL := $(L1_RPC_URL)

.PHONY: prepare
prepare: validate-config
