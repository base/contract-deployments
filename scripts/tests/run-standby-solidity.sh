#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
forge=$(mise -C "$root" which forge)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/script" "$fixture/test" "$fixture/lib"
for dependency in "$root"/active/evm/lib/*; do
    cp -R "$dependency" "$fixture/lib/$(basename "$dependency")"
done
cp "$root/active/evm/foundry.toml" "$fixture/foundry.toml"
cp "$root/scripts/tests/DelayUpgradeActivation.t.sol" "$fixture/test/"
cp "$root/scripts/tests/SimulationFixtures.sol" "$fixture/test/"
cp "${STANDBY_SCRIPT_SOURCE:-$root/standby/evm/tasks/delay-upgrade-activation/script/DelayUpgradeActivation.s.sol}" "$fixture/script/"
cd "$fixture"
# Foundry env writes are process-global, so concurrent fixture tests can overwrite each other's inputs.
if [ -n "${STANDBY_VALIDATION_OUT:-}" ]; then
    EXPORT_VALIDATION_FIXTURE=true "$forge" test --threads 1 --match-test test_exportValidationFixture -vv
    cp validation-fixture.json "$STANDBY_VALIDATION_OUT"
    cp stateDiff.json "$STANDBY_STATE_DIFF_OUT"
else
    "$forge" test --threads 1 -vv
fi
