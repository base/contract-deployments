#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
node=$(mise -C "$root" which node)
npm=$(mise -C "$root" which npm)
export PATH="$(dirname "$node"):$PATH"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
pin=$(sed -n 's/^SIGNER_TOOL_COMMIT=//p' "$root/Makefile")
signer="$fixture/signer"
mkdir -p "$signer"
git -C "$signer" init -q
git -C "$signer" remote add origin https://github.com/base/task-signing-tool.git
git -C "$signer" fetch -q --depth=1 origin "$pin"
git -C "$signer" reset -q --hard FETCH_HEAD
sh "$root/scripts/apply-signer-standby.sh" "$signer"
if sh "$root/scripts/apply-signer-standby.sh" "$signer" > "$fixture/reapply.log" 2>&1; then
    echo "patch accepted modified upstream content" >&2
    exit 1
fi
grep -q 'upstream content differs from pin' "$fixture/reapply.log"
mkdir "$fixture/wrong-pin"
git -C "$fixture/wrong-pin" init -q
if sh "$root/scripts/apply-signer-standby.sh" "$fixture/wrong-pin" > "$fixture/pin.log" 2>&1; then
    echo "patch accepted unpinned upstream" >&2
    exit 1
fi
grep -q 'upstream pin mismatch' "$fixture/pin.log"
mkdir -p "$signer/__tests__"
cp "$root/scripts/tests/signer-standby.test.ts" "$signer/__tests__/standby.test.ts"
cd "$signer"
"$npm" ci --ignore-scripts --no-audit --no-fund
"$npm" test -- --runTestsByPath __tests__/standby.test.ts \
    src/lib/__tests__/deployments.test.ts \
    src/app/api/upgrade-config/__tests__/route.test.ts \
    src/app/api/install-deps/__tests__/route.test.ts
cd "$root"
STANDBY_SIGNER_HOME="$signer" STANDBY_SOLIDITY_INTEGRATION=1 python3 -m unittest discover -s scripts/tests -v
