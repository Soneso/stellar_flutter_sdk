#!/bin/bash
# Compare generated XDR files against originals after dart format.
# Usage: ./compare.sh [file_pattern]
# Examples:
#   ./compare.sh                    # Compare all modified files
#   ./compare.sh xdr_payment_op     # Compare one specific file
#
# Requires: dart format, git

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
XDR_DIR="$REPO_ROOT/lib/src/xdr"
PATTERN="${1:-}"

cd "$REPO_ROOT"

# Get list of modified XDR files
if [ -n "$PATTERN" ]; then
  FILES=$(git diff --name-only -- "lib/src/xdr/*${PATTERN}*" 2>/dev/null || true)
else
  FILES=$(git diff --name-only -- lib/src/xdr/)
fi

if [ -z "$FILES" ]; then
  echo "No modified XDR files found."
  exit 0
fi

EXACT=0
DIFF=0
TOTAL=0
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

for FILE in $FILES; do
  BASENAME=$(basename "$FILE")
  TOTAL=$((TOTAL + 1))

  # Format the generated (current working tree) version
  cp "$FILE" "$TMPDIR/generated_$BASENAME"
  dart format "$TMPDIR/generated_$BASENAME" > /dev/null 2>&1

  # Format the original (git HEAD) version
  git show "HEAD:$FILE" > "$TMPDIR/original_$BASENAME" 2>/dev/null
  dart format "$TMPDIR/original_$BASENAME" > /dev/null 2>&1

  # Compare
  if diff -q "$TMPDIR/original_$BASENAME" "$TMPDIR/generated_$BASENAME" > /dev/null 2>&1; then
    EXACT=$((EXACT + 1))
    echo "EXACT:  $BASENAME"
  else
    DIFF=$((DIFF + 1))
    echo "DIFF:   $BASENAME"
    if [ -n "$PATTERN" ] || [ "$TOTAL" -le 5 ]; then
      # Show diff for targeted comparisons or first few files
      diff "$TMPDIR/original_$BASENAME" "$TMPDIR/generated_$BASENAME" || true
      echo "---"
    fi
  fi
done

echo ""
echo "Summary: $EXACT exact, $DIFF with diffs, $TOTAL total"
