#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
export DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/shell/functions.sh"

output=$(tradecraft)

test_case "renders the title"
echo "$output" | grep -q "Tradecraft: Working with guinetik"
assert_true $? "title present"

test_case "renders one bullet line per data bullet"
expected=$(grep -c '^-|' "$DOTFILES/tradecraft.psv")
actual=$(echo "$output" | grep -c '✓')
assert_equal "$actual" "$expected" "bullet count matches data file"

test_case "no longer mentions the nonexistent tour command"
echo "$output" | grep -q "'tour'"
[ $? -ne 0 ]
assert_true $? "tour is gone"

test_case "describes Windows as the daily driver"
echo "$output" | grep -q "Windows 11 native"
assert_true $? "ecosystem is current"

test_case "tradecraft is self-locating: works with DOTFILES unset, sourced through a symlink"
scratch="$(mktemp -d)"
mkdir -p "$scratch/config/shell"
# MSYS=winsymlinks:nativestrict makes `ln -s` create a real symlink under
# Git Bash on Windows (it otherwise silently falls back to a copy); it is a
# no-op everywhere else.
MSYS=winsymlinks:nativestrict ln -s "$DOTFILES/shell/functions.sh" "$scratch/config/shell/functions.sh"
unset_output=$(env -u DOTFILES bash -c "source '$scratch/config/shell/functions.sh'; tradecraft" 2>&1)
unset_status=$?
rm -rf "$scratch"
assert_true "$unset_status" "tradecraft exits 0 with DOTFILES unset (real install has no DOTFILES set)"
echo "$unset_output" | grep -q "Tradecraft: Working with guinetik"
assert_true $? "tradecraft produced real data output, not a 'data file not found' error"

test_summary
