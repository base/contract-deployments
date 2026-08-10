#!/bin/bash
set -euo pipefail

# Configuration: Networks to validate
NETWORKS=(
  "mainnet"
  "sepolia"
  "sepolia-alpha"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

VALIDATION_FAILED=0
VALIDATION_PASSED=0

echo "🔍 Validating task signatures..."

# Build regex pattern from networks
NETWORK_PATTERN=$(IFS='|'; echo "${NETWORKS[*]}")

# Get changed task directories
TASK_DIRS=$(git diff --name-only origin/main...HEAD \
  | grep -E "^($NETWORK_PATTERN)/[^/]+/" \
  | sed -E 's|^([^/]+/[^/]+)/.*|\1|' \
  | sort -u || true)

if [ -z "$TASK_DIRS" ]; then
  echo "ℹ️  No task folders modified. Skipping validation."
  exit 0
fi

echo "📋 Tasks to validate:"
echo "$TASK_DIRS" | sed 's/^/   - /'
echo ""

base64_to_hex() {
  echo "$1" | base64 -d | od -An -tx1 | tr -d ' \n'
}

# Validate a single signature file
validate_signature_file() {
  local sig_file="$1"
  local computed_hash="$2"
  local sig_name=$(basename "$sig_file" .json)

  echo "🔍 Checking $sig_name..."

  # Check if file exists
  if [ ! -f "$sig_file" ]; then
    echo -e "${RED}   ❌ Missing signature file${NC}"
    return 1
  fi

  # Validate JSON
  if ! jq empty "$sig_file" 2>/dev/null; then
    echo -e "${RED}   ❌ Invalid JSON${NC}"
    return 1
  fi

  # Check algorithm
  local algorithm=$(jq -r '.messageSignature.messageDigest.algorithm // empty' "$sig_file")
  if [ "$algorithm" != "SHA2_384" ]; then
    echo -e "${RED}   ❌ Wrong algorithm: $algorithm (expected SHA2_384)${NC}"
    return 1
  fi

  # Extract digest
  local base64_digest=$(jq -r '.messageSignature.messageDigest.digest // empty' "$sig_file")
  if [ -z "$base64_digest" ]; then
    echo -e "${RED}   ❌ No digest found${NC}"
    return 1
  fi

  # Compare hashes
  local sig_hash=$(base64_to_hex "$base64_digest")
  if [ "$computed_hash" = "$sig_hash" ]; then
    echo -e "${GREEN}   ✓ Hash matches${NC}"
    return 0
  else
    echo -e "${RED}   ❌ Hash mismatch${NC}"
    echo -e "${RED}      Expected: $computed_hash${NC}"
    echo -e "${RED}      Got:      $sig_hash${NC}"
    return 1
  fi
}

# Validate a task
validate_task() {
  local task_dir="$1"
  local network=$(echo "$task_dir" | cut -d'/' -f1)
  local task_name=$(echo "$task_dir" | cut -d'/' -f2)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Validating: $task_dir"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check task directory exists
  if [ ! -d "$task_dir" ]; then
    echo -e "${RED}❌ Task directory not found${NC}"
    return 1
  fi

  # Create deterministic tarball
  local temp_tar=$(mktemp)
  trap "rm -f $temp_tar" EXIT

  echo "📦 Creating deterministic tarball..."
  if ! tar --sort=name \
      --mtime='1970-01-01 00:00:00' \
      --owner=0 --group=0 \
      --numeric-owner \
      -C "$network" \
      -cf "$temp_tar" \
      "$task_name/" 2>/dev/null; then
    echo -e "${RED}❌ Failed to create tarball${NC}"
    return 1
  fi

  # Compute hash
  echo "🔐 Computing SHA2-384 hash..."
  local computed_hash=$(openssl dgst -sha384 -binary "$temp_tar" | od -An -tx1 | tr -d ' \n')
  echo "   Computed: $computed_hash"
  echo ""

  # Validate each signature file
  local sig_dir="signatures/$network/$task_name"
  local sig_files=("$sig_dir/author.json" "$sig_dir/base-facilitator.json" "$sig_dir/base-sc-facilitator.json")
  local all_match=true

  for sig_file in "${sig_files[@]}"; do
    if ! validate_signature_file "$sig_file" "$computed_hash"; then
      all_match=false
    fi
  done

  echo ""
  if [ "$all_match" = true ]; then
    echo -e "${GREEN}✅ PASSED${NC}"
    return 0
  else
    echo -e "${RED}❌ FAILED${NC}"
    return 1
  fi
}

# Validate all tasks
while IFS= read -r task_dir; do
  if validate_task "$task_dir"; then
    VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
  else
    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
  fi
  echo ""
done <<< "$TASK_DIRS"

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "   ${GREEN}Passed: $VALIDATION_PASSED${NC}"
echo -e "   ${RED}Failed: $VALIDATION_FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $VALIDATION_FAILED -gt 0 ]; then
  echo -e "${RED}❌ Signature validation failed${NC}"
  exit 1
fi

echo -e "${GREEN}✅ All signatures validated successfully${NC}"
exit 0
