#!/bin/bash

DEPLOY_FIELDS='"baseFeeVaultRecipient","batchSenderAddress","controller","deployerAddress","finalSystemOwner","finalizationPeriodSeconds","gasPriceOracleOverhead","gasPriceOracleScalar","l1ChainID","l1FeeVaultRecipient","l2BlockTime","l2ChainID","l2OutputOracleChallenger","l2OutputOracleProposer","l2OutputOracleStartingBlockNumber","l2OutputOracleStartingTimestamp","l2OutputOracleSubmissionInterval","p2pSequencerAddress","portalGuardian","proxyAdminOwnerL2","sequencerFeeVaultRecipient"'

DEPLOY_CONFIG_FILE="inputs/deploy-config.json"
MISC_CONFIG_FILE="inputs/misc-config.json"
FOUNDRY_CONFIG_FILE="inputs/foundry-config.json"

# Convert field from hex to decimal
VALUE=$(jq -r '.l2GenesisBlockGasLimit' "$DEPLOY_CONFIG_FILE")
GAS_LIMIT=$(printf %d $VALUE)

# Construct config file which will be the input in deploy script
jq -s '.[0] * .[1]' "$DEPLOY_CONFIG_FILE" "$MISC_CONFIG_FILE" | \
jq "with_entries(select([.key] | inside([$DEPLOY_FIELDS])))" | \
jq --arg l2GenesisBlockGasLimit $GAS_LIMIT '. + {l2GenesisBlockGasLimit: $l2GenesisBlockGasLimit | tonumber}' | \
jq --sort-keys | \
jq '{"deployConfig": .}' > "$FOUNDRY_CONFIG_FILE"
