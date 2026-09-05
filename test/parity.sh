#!/usr/bin/env bash
# parity.sh - cross-language structural drift check for tradecraft.
#
# Renders `tradecraft` from both the bash and PowerShell implementations,
# normalizes away purely cosmetic differences (ANSI color codes, the
# fixed-vs-computed-width box border rules, trailing whitespace/CR), and
# diffs the result WITHOUT sorting. This compares the whole document in
# order - section headings, bullets in their section, the tip header, and
# every tip - not just the multiset of bullet lines.
#
# Not named *.tests.sh: it shells out to pwsh and is invoked explicitly,
# not as part of the bash unit suite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

bash_out="$(mktemp)"
pwsh_out="$(mktemp)"
trap 'rm -f "$bash_out" "$pwsh_out"' EXIT

normalize() {
  # strip ANSI escape codes, drop pure border lines (╭.../╰...), strip
  # trailing whitespace (including any stray \r), do not sort/reorder.
  sed 's/\x1b\[[0-9;]*m//g' \
    | grep -v '^[╭╰]' \
    | sed 's/[[:space:]]*$//'
}

bash -c "export DOTFILES='$ROOT'; source '$ROOT/shell/functions.sh'; tradecraft" \
  | normalize > "$bash_out"

WIN_ROOT="$(cygpath -w "$ROOT" 2>/dev/null || echo "$ROOT")"
pwsh -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; . '$WIN_ROOT\powershell\functions.ps1'; tradecraft" \
  | normalize > "$pwsh_out"

if diff -u "$bash_out" "$pwsh_out"; then
  echo "RENDERERS AGREE"
  exit 0
else
  echo "RENDERERS DISAGREE" >&2
  exit 1
fi
