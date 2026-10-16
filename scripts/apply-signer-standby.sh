#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
signer=${1:?signer checkout required}
pin=8e059b65ddf936f2fcfd3c820544f8576f74bd35
patch_file="$root/scripts/patches/signer-standby.patch"
git -C "$signer" diff --quiet HEAD -- || { echo "standby signer patch: upstream content differs from pin" >&2; exit 1; }
if [ "$(git -C "$signer" rev-parse HEAD)" = "$pin" ]; then
	git -C "$signer" apply --check "$patch_file"
	git -C "$signer" apply "$patch_file"
	exit 0
fi
# test/e2e only: allow testing unreleased signer-tool commits (make sign-task SIGNER_TOOL_COMMIT=<commit>).
# The patch is applied with line-offset tolerance and must still apply without rejects.
echo "standby signer patch: $(git -C "$signer" rev-parse HEAD) is not the reviewed pin; applying with offsets (test/e2e)" >&2
(cd "$signer" && patch -p1 --dry-run -s <"$patch_file" && patch -p1 -s <"$patch_file")
find "$signer/src" -name '*.orig' -delete
