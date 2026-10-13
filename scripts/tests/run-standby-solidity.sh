#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
forge=$(mise -C "$root" which forge)
if [ -n "${STANDBY_PROJECT_DIR:-}" ]; then
    fixture=$STANDBY_PROJECT_DIR
else
    fixture=$(mktemp -d)
    trap 'rm -rf "$fixture"' EXIT HUP INT TERM
fi
if [ ! -f "$fixture/foundry.toml" ]; then
    mkdir -p "$fixture/script" "$fixture/test" "$fixture/lib"
    for dependency in "$root"/active/evm/lib/*; do
        cp -R "$dependency" "$fixture/lib/$(basename "$dependency")"
    done
    cp "$root/active/evm/foundry.toml" "$fixture/foundry.toml"
    cp "$root/scripts/tests/DelayUpgradeActivation.t.sol" "$fixture/test/"
    cp "$root/scripts/tests/SimulationFixtures.sol" "$fixture/test/"
    if [ "${STANDBY_BASELINE:-0}" = 1 ]; then
        sed 's/DelayCobaltActivation/DelayUpgradeActivation/g' \
            "$root/archive/evm/2026-09-16-delay-cobalt-activation-to-2000/script/DelayCobaltActivation.s.sol" \
            > "$fixture/script/DelayUpgradeActivation.s.sol"
    elif [ -n "${STANDBY_SCRIPT_SOURCE:-}" ]; then
        cp "$STANDBY_SCRIPT_SOURCE" "$fixture/script/DelayUpgradeActivation.s.sol"
    else
        cp "$root/standby/evm/tasks/delay-upgrade-activation/script/DelayUpgradeActivation.s.sol" "$fixture/script/"
    fi
fi
cd "$fixture"
if [ "${STANDBY_PREPARE_ONLY:-0}" = 1 ]; then
    "$forge" build
    exit
fi
# Foundry env writes are process-global, so concurrent fixture tests can overwrite each other's inputs.
if [ -n "${STANDBY_VALIDATION_OUT:-}" ]; then
    EXPORT_VALIDATION_FIXTURE=true "$forge" test --threads 1 --match-test test_exportValidationFixture -vv
    cp validation-fixture.json "$STANDBY_VALIDATION_OUT"
    if [ -n "${STANDBY_STATE_DIFF_OUT:-}" ]; then
        cp stateDiff.json "$STANDBY_STATE_DIFF_OUT"
    fi
else
    "$forge" test --threads 1 -vv
fi
