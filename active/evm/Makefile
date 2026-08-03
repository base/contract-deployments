EVM_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(EVM_ROOT)/../../Makefile
include $(EVM_ROOT)/../../Multisig.mk

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Usage: make -C active/evm TASK_ID=<task-id> TASK_NETWORK=<network> <target>"

# Help does not need a task. Every operational target does.
REQUESTED_GOALS := $(if $(MAKECMDGOALS),$(MAKECMDGOALS),help)
ifneq ($(strip $(filter-out help,$(REQUESTED_GOALS))),)
ifeq ($(strip $(TASK_ID)),)
$(error TASK_ID is required)
endif

TASKS_DIR := $(realpath $(EVM_ROOT)/tasks)
TASK_DIR := $(realpath $(TASKS_DIR)/$(TASK_ID))
ifeq ($(TASK_DIR),)
$(error Task does not exist: tasks/$(TASK_ID))
endif
ifneq ($(abspath $(dir $(TASK_DIR))),$(TASKS_DIR))
$(error TASK_ID must name one direct child of active/evm/tasks)
endif

TASK_MK := $(TASK_DIR)/Task.mk
ifeq ($(wildcard $(TASK_MK)),)
$(error Missing $(TASK_MK))
endif
include $(TASK_MK)

ifeq ($(strip $(TASK_NETWORK)),)
$(error TASK_NETWORK is required, either on the command line or in Task.mk)
endif

CONFIG_ROOT := $(realpath $(TASK_DIR)/config)
CONFIG_DIR := $(realpath $(CONFIG_ROOT)/$(TASK_NETWORK))
ifeq ($(CONFIG_DIR),)
$(error Task network does not exist: tasks/$(TASK_ID)/config/$(TASK_NETWORK))
endif
ifneq ($(abspath $(dir $(CONFIG_DIR))),$(CONFIG_ROOT))
$(error TASK_NETWORK must name one direct child of the task config directory)
endif

TASK_DIR_REL := tasks/$(TASK_ID)
CONFIG_DIR_REL := $(TASK_DIR_REL)/config/$(TASK_NETWORK)

include $(CONFIG_DIR)/network.env
include $(CONFIG_DIR)/.env

SUPPORTED_OPERATIONS := funding gas safe-management bridge-threshold pause-bridge superchain-pause custom
ifneq ($(words $(OPERATION)),1)
$(error OPERATION must contain exactly one operation name)
endif
ifeq ($(filter $(SUPPORTED_OPERATIONS),$(OPERATION)),)
$(error Unsupported OPERATION "$(OPERATION)"; expected one of: $(SUPPORTED_OPERATIONS))
endif

PROJECT_DIR := $(EVM_ROOT)
SIGNER_TOOL_PATH := $(REPO_ROOT)/signer-tool
VALIDATIONS_DIR := $(EVM_ROOT)/$(CONFIG_DIR_REL)/validations
TASK_ORIGIN_DIR := $(EVM_ROOT)/$(CONFIG_DIR_REL)
SIGNATURE_DIR := $(EVM_ROOT)/$(TASK_DIR_REL)/signatures/$(TASK_NETWORK)
RPC_URL ?= $(L1_RPC_URL)

ifneq ($(OPERATION),custom)
include $(EVM_ROOT)/make/$(OPERATION).mk
endif

.PHONY: show-config
show-config:
	@echo "OPERATION=$(OPERATION)"
	@echo "SCRIPT_NAME=$(SCRIPT_NAME)"
	@echo "CONFIG_DIR=$(CONFIG_DIR_REL)"
endif
