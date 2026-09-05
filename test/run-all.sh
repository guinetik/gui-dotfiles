#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
for file in "$SCRIPT_DIR"/*.tests.sh; do
  printf '\n=== %s ===\n' "$(basename "$file")"
  output=$(bash "$file" 2>&1)
  status=$?
  printf '%s\n' "$output"
  # A file that prints FAIL but exits 0 forgot to call test_summary. Do not
  # let that read as success — a silently green suite is worse than a red one.
  if [ "$status" -ne 0 ] || printf '%s' "$output" | grep -q '^ *FAIL'; then
    failed=$((failed + 1))
    if [ "$status" -eq 0 ]; then
      printf '  (this file printed FAIL but exited 0 — missing test_summary?)\n'
    fi
  fi
done
if [ "$failed" -gt 0 ]; then
  printf '\n%d test file(s) failed\n' "$failed"
  exit 1
fi
printf '\nAll test files passed\n'
