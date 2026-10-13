#!/usr/bin/env bash
set -euo pipefail
umask 077

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

for variable in TASK_NETWORK L1_RPC_URL INCIDENT_MULTISIG SYSTEM_CONFIG LEDGER_ACCOUNT MISE; do
    [[ -n ${!variable:-} ]] || fail "$variable is required"
done
[[ $TASK_NETWORK =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || fail "Invalid TASK_NETWORK"
[[ $LEDGER_ACCOUNT =~ ^[0-9]+$ ]] || fail "LEDGER_ACCOUNT must be a nonnegative integer"
address_pattern='^0x[0-9a-fA-F]{40}$'
hash_pattern='^0x[0-9a-fA-F]{64}$'
signature_pattern='^[0-9a-fA-F]{130}$'
[[ $INCIDENT_MULTISIG =~ $address_pattern && $SYSTEM_CONFIG =~ $address_pattern ]] || fail "Invalid Safe or SystemConfig address"
config="config/$TASK_NETWORK"
[[ -d $config ]] || fail "Missing $config"
state="$config/.pause-signing"
output="$config/signatures-pause.txt"
lock="$config/.pause-signing.lock"
mkdir "$lock" 2>/dev/null || fail "Signing is already locked for $TASK_NETWORK. If no signing process is running, remove $lock and rerun make TASK_NETWORK=$TASK_NETWORK sign-pause."
cleanup() {
    rm -f "$state/sign-output" "$state/sign-errors" "$state/current-context" "$state/next-signature"
    rmdir "$lock"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
[[ ! -e $output ]] || fail "$output already exists. Send its contents to the facilitator; do not overwrite a completed batch."
mkdir -p "$state"

mise_exec() {
    "$MISE" exec -- "$@"
}
cast() {
    mise_exec cast "$@"
}
recovery() {
    printf 'Do not send partial signatures. Successful signatures are saved in %s.\n' "$state" >&2
    printf 'Unlock the Ledger, open the Ethereum app, then rerun make TASK_NETWORK=%s sign-pause with the same Ledger account.\n' "$TASK_NETWORK" >&2
}
trap 'recovery' ERR

goroot=$(mise_exec go env GOROOT)
[[ -n $goroot && -x $goroot/bin/eip712sign ]] || fail "Missing GOROOT/bin/eip712sign. Run make TASK_NETWORK=$TASK_NETWORK deps-pause."
start_nonce_hex=$(cast call "$INCIDENT_MULTISIG" 'nonce()(uint256)' --rpc-url "$L1_RPC_URL")
start_nonce=$(cast to-dec "$start_nonce_hex")
[[ $start_nonce =~ ^(0|[1-9][0-9]{0,17})$ ]] || fail "Safe nonce is not a supported nonnegative integer"
chain_id=$(cast chain-id --rpc-url "$L1_RPC_URL")
superchain_config=$(cast call "$SYSTEM_CONFIG" 'superchainConfig()(address)' --rpc-url "$L1_RPC_URL")
domain_separator=$(cast call "$INCIDENT_MULTISIG" 'domainSeparator()(bytes32)' --rpc-url "$L1_RPC_URL")
[[ $superchain_config =~ $address_pattern && $domain_separator =~ $hash_pattern ]] || fail "Invalid signing context from RPC"
zero_address=0x0000000000000000000000000000000000000000
call_data=$(cast calldata 'pause(address)' "$zero_address")
call_data_hash=$(cast keccak "$call_data")
[[ $call_data_hash =~ $hash_pattern ]] || fail "Invalid pause calldata hash"
printf '%s\n' "$TASK_NETWORK" "$L1_RPC_URL" "$chain_id" "$INCIDENT_MULTISIG" "$SYSTEM_CONFIG" \
    "$superchain_config" "$domain_separator" "$call_data_hash" "$LEDGER_ACCOUNT" "$start_nonce" > "$state/current-context"
if [[ -f $state/context ]]; then
    cmp -s "$state/context" "$state/current-context" || fail "Signing context changed. Keep $state and contact the facilitator before restarting; do not send partial signatures."
else
    mv "$state/current-context" "$state/context"
fi

safe_tx_typehash=0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8
safe_tx_abi='f(bytes32,address,uint256,bytes32,uint8,uint256,uint256,uint256,address,address,uint256)'
batch_signer=''
saw_missing=false
printf 'Signing 20 pause transactions on %s, starting at Safe nonce %s.\n' "$TASK_NETWORK" "$start_nonce"
for ((i = 0; i < 20; i++)); do
    nonce=$((start_nonce + i))
    if [[ -f $state/$i ]]; then
        [[ $saw_missing == false ]] || fail "Saved signatures have a gap. Keep $state and contact the facilitator."
        IFS=: read -r signer saved_nonce sig extra < "$state/$i"
        [[ $signer =~ $address_pattern && $sig =~ $signature_pattern && $saved_nonce == "$nonce" && -z $extra ]] || fail "Invalid saved signature. Keep $state and contact the facilitator."
    else
        saw_missing=true
        safe_tx=$(cast abi-encode "$safe_tx_abi" "$safe_tx_typehash" "$superchain_config" 0 "$call_data_hash" \
            0 0 0 0 "$zero_address" "$zero_address" "$nonce")
        message_hash=$(cast keccak "$safe_tx")
        [[ $message_hash =~ $hash_pattern ]] || fail "Invalid Safe transaction hash"
        signing_data="0x1901${domain_separator#0x}${message_hash#0x}"
        signed=false
        for ((attempt = 1; attempt <= 3; attempt++)); do
            printf 'Approve nonce %s on the Ledger, attempt %s/3.\n' "$nonce" "$attempt"
            if mise_exec "$goroot/bin/eip712sign" --ledger --hd-paths "m/44'/60'/$LEDGER_ACCOUNT'/0/0" \
                -data "$signing_data" > "$state/sign-output" 2> "$state/sign-errors"; then
                signer=$(awk '/^Signer:/ {print $2}' "$state/sign-output")
                sig=$(awk '/^Signature:/ {print $2}' "$state/sign-output")
                if [[ $signer =~ $address_pattern && $sig =~ $signature_pattern ]]; then
                    signed=true
                    break
                fi
            fi
            printf 'Ledger signing failed or returned invalid output at nonce %s. Unlock the Ledger and open the Ethereum app before retrying this nonce.\n' "$nonce" >&2
        done
        if [[ $signed != true ]]; then
            recovery
            fail "Stopped at nonce $nonce after 3 attempts."
        fi
        [[ -z $batch_signer || $batch_signer == "$signer" ]] || fail "Ledger signer changed. Keep $state and resume with the original Ledger; do not send partial signatures."
        # Atomic checkpoints exclude failed attempts and survive an interrupted batch.
        printf '%s:%s:%s\n' "$signer" "$nonce" "$sig" > "$state/next-signature"
        mv "$state/next-signature" "$state/$i"
    fi
    [[ -z $batch_signer || $batch_signer == "$signer" ]] || fail "Saved Ledger signer changed. Keep $state and contact the facilitator."
    batch_signer=$signer
    printf 'Saved signature %s/20 for nonce %s.\n' "$((i + 1))" "$nonce"
done

for ((i = 0; i < 20; i++)); do
    printf '%s,' "$(cat "$state/$i")"
done > "$state/batch"
printf '\n' >> "$state/batch"
mv "$state/batch" "$output"
rm -rf "$state"
printf 'Send the contents of %s to the facilitator. Do not send terminal output.\n' "$output"
