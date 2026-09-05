#!/usr/bin/env bash
# Minimal assert harness, mirroring test/assert.ps1. No dependencies on
# purpose: this repo bootstraps bare machines.

PASSED=0
FAILED=0
CURRENT_CASE=""

test_case() { CURRENT_CASE="$1"; }

assert_equal() {
  local actual="$1" expected="$2" message="$3"
  if [ "$actual" = "$expected" ]; then
    PASSED=$((PASSED + 1))
    printf '  PASS  %s: %s\n' "$CURRENT_CASE" "$message"
  else
    FAILED=$((FAILED + 1))
    printf '  FAIL  %s: %s\n        expected: <%s>\n        actual:   <%s>\n' \
      "$CURRENT_CASE" "$message" "$expected" "$actual"
  fi
}

assert_true() {
  local status="$1" message="$2"
  if [ "$status" -eq 0 ]; then
    PASSED=$((PASSED + 1))
    printf '  PASS  %s: %s\n' "$CURRENT_CASE" "$message"
  else
    FAILED=$((FAILED + 1))
    printf '  FAIL  %s: %s\n' "$CURRENT_CASE" "$message"
  fi
}

test_summary() {
  printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
  [ "$FAILED" -eq 0 ] || exit 1
}
