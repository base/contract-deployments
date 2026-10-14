#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
forge=$(mise -C "$root" which forge)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/script" "$fixture/test" "$fixture/lib"
cp "$root/active/evm/foundry.toml" "$fixture/foundry.toml"
operation=${STANDBY_OPERATION:-delay-upgrade-activation}
case "$operation" in
    delay-upgrade-activation)
        dependencies="$root/active/evm/lib"
        test=DelayUpgradeActivation.t.sol
        ;;
    update-verifier-hashes)
        export FOUNDRY_SOLC_VERSION=0.8.15 FOUNDRY_OPTIMIZER=true FOUNDRY_OPTIMIZER_RUNS=999999
        export FOUNDRY_BYTECODE_HASH=none FOUNDRY_EVM_VERSION=cancun FOUNDRY_VIA_IR=false
        test=VerifierHashes.t.sol
        if [ -n "${STANDBY_DEPS_SOURCE:-}" ]; then
            dependencies="$STANDBY_DEPS_SOURCE"
        else
            make -C "$root" forge-deps PROJECT_DIR="$fixture" BASE_CONTRACTS_COMMIT=8c21f6d08a36b4059ae2bb8938f1e7e758a0e962
            (cd "$fixture" && "$forge" install --no-git github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@0a2cb9a445c365870ed7a8ab461b12acf3e27d63)
            dependencies="$fixture/lib"
        fi
        ;;
    *) echo "unsupported standby fixture operation: $operation" >&2; exit 1 ;;
esac
if [ "$dependencies" != "$fixture/lib" ]; then
    for dependency in "$dependencies"/*; do
        cp -R "$dependency" "$fixture/lib/$(basename "$dependency")"
    done
fi
cp "$root/scripts/tests/$test" "$fixture/test/"
cp "$root/scripts/tests/SimulationFixtures.sol" "$fixture/test/"
source=${STANDBY_SCRIPT_SOURCE:-$root/standby/evm/tasks/$operation/script}
if [ -d "$source" ]; then
    cp "$source"/*.sol "$fixture/script/"
else
    cp "$source" "$fixture/script/"
fi
cd "$fixture"
# Foundry env writes are process-global, so concurrent fixture tests can overwrite each other's inputs.
if [ -n "${STANDBY_VALIDATION_OUT:-}" ]; then
    EXPORT_VALIDATION_FIXTURE=true "$forge" test --threads 1 --match-test test_exportValidationFixture -vv
    cp validation-fixture.json "$STANDBY_VALIDATION_OUT"
    cp stateDiff.json "$STANDBY_STATE_DIFF_OUT"
    if [ -n "${STANDBY_ADDRESSES_OUT:-}" ]; then
        cp config/local/addresses.json "$STANDBY_ADDRESSES_OUT"
    fi
else
    "$forge" fmt --check script/ test/
    "$forge" build
    "$forge" test --threads 1 -vv
fi
