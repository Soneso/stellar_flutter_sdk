#!/usr/bin/env bash
#
# Compiles the SEP-0051 nesting-guard harness to WasmGC and runs it under Node.
#
# `flutter test` has no WasmGC platform, so this is the only thing that observes
# the target at all. It is what turns the guard's boundary behaviour from an
# assumption into a checked property: see sep51_wasm_smoke.dart for what the
# harness asserts and why a failure there can arrive as a dead process rather
# than as a failed assertion.
#
# Usage:
#   tool/sep51_wasm_smoke/run.sh
#
# Exit codes:
#   0  the guard holds on WasmGC
#   1  the guard does not hold, or the module died running
#   2  a prerequisite is missing (dart or node)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.tmp"
ENTRY="$SCRIPT_DIR/sep51_wasm_smoke.dart"
LOADER="$SCRIPT_DIR/run_smoke.mjs"
MODULE="$BUILD_DIR/sep51_wasm_smoke.wasm"
INIT="$BUILD_DIR/sep51_wasm_smoke.mjs"

# Prerequisites first, before anything is compiled or written, so a missing
# toolchain can never be mistaken for a guard that failed.
for tool in dart node; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "run.sh: $tool is not on PATH." >&2
    exit 2
  fi
done

for file in "$ENTRY" "$LOADER"; do
  if [ ! -f "$file" ]; then
    echo "run.sh: $file does not exist." >&2
    exit 2
  fi
done

mkdir -p "$BUILD_DIR"
rm -f "$BUILD_DIR"/*

if ! dart compile wasm "$ENTRY" -o "$MODULE"; then
  echo "run.sh: the harness did not compile to WasmGC." >&2
  exit 1
fi

node "$LOADER" "$MODULE" "$INIT"
status=$?
if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "run.sh: the WasmGC nesting guard smoke test failed (exit $status)." >&2
  echo "  A stack trace ending in 'Maximum call stack size exceeded' means the" >&2
  echo "  guard let an over-nested document reach the host, which on this target" >&2
  echo "  ends the process rather than throwing." >&2
  exit 1
fi

echo "SEP-0051 nesting guard holds on WasmGC."
