#!/usr/bin/env bash
# Pipe-delimited record reading for bash. Mirrors powershell/lib/psv.ps1.
# Callers parse fields with: IFS='|' read -r key rest

psv_filter() {
  local path="$1"
  [ -f "$path" ] || { echo "PSV file not found: $path" >&2; return 1; }
  grep -v '^[[:space:]]*#' "$path" | grep -v '^[[:space:]]*$'
}
