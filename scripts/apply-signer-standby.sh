#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
signer=${1:?signer checkout required}
pin=8e059b65ddf936f2fcfd3c820544f8576f74bd35
[ "$(git -C "$signer" rev-parse HEAD)" = "$pin" ] || { echo "standby signer patch: upstream pin mismatch" >&2; exit 1; }
git -C "$signer" diff --quiet HEAD -- || { echo "standby signer patch: upstream content differs from pin" >&2; exit 1; }
git -C "$signer" apply --check "$root/scripts/patches/signer-standby.patch"
git -C "$signer" apply "$root/scripts/patches/signer-standby.patch"
