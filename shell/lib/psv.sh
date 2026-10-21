#!/usr/bin/env bash
# Pipe-delimited record reading for bash. Mirrors powershell/lib/psv.ps1.
# Callers parse fields with: IFS='|' read -r key rest

psv_filter() {
  # Not `path`: in zsh that name is tied to $PATH, and `local path=...`
  # empties PATH for the function's duration, so grep itself goes missing.
  local file="$1"
  [ -f "$file" ] || { echo "PSV file not found: $file" >&2; return 1; }
  grep -v '^[[:space:]]*#' "$file" | grep -v '^[[:space:]]*$'
}
