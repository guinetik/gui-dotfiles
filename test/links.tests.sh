#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "every link source exists in the repo"
missing=0
while IFS='|' read -r src target; do
  [ -f "$ROOT/$src" ] || { echo "    missing source: $src"; missing=$((missing + 1)); }
done < <(psv_filter "$ROOT/linux/links.psv")
assert_equal "$missing" "0" "no missing sources"

# The original hardcoded SYMLINKS array from common/create_symlinks.sh, as it
# stood at 5eeb532 — the commit before the map was extracted into
# linux/links.psv. Golden values, pinned deliberately.
#
# An earlier version of this test read them from `git show HEAD:...`, which
# worked only while the extraction was uncommitted: once committed, HEAD holds
# the rewritten script with no array in it, the expected count silently becomes
# zero, and the test invalidates itself at the exact moment it starts mattering.
# It also broke in a shallow clone. Expectations that float with HEAD are not
# expectations. If you intentionally add or remove a link, update this list in
# the same commit — that edit is the point, not an obstacle.
old_links="bash/.bashrc:\$HOME/.bashrc
zsh/.zshrc:\$HOME/.zshrc
zsh/.zshenv:\$HOME/.zshenv
zsh/.zsh_plugins.txt:\$HOME/.zsh_plugins.txt
shell/aliases.sh:\$HOME/.config/shell/aliases.sh
shell/functions.sh:\$HOME/.config/shell/functions.sh
starship/starship.toml:\$HOME/.config/starship.toml
git/.gitconfig:\$HOME/.gitconfig
.claude/CLAUDE.md:\$HOME/.claude/CLAUDE.md"

test_case "link map covers the same count as the old hardcoded array"
expected_count=$(echo "$old_links" | grep -c .)
actual_count=$(psv_filter "$ROOT/linux/links.psv" | wc -l)
assert_equal "$actual_count" "$expected_count" "link count matches old hardcoded array"

test_case "every link target matches the old hardcoded array"
mismatches=0
while IFS=':' read -r src expected_target; do
  [ -z "$src" ] && continue
  actual_target=$(psv_filter "$ROOT/linux/links.psv" | awk -F'|' -v s="$src" '$1==s{print $2}')
  if [ "$actual_target" != "$expected_target" ]; then
    echo "    target mismatch for $src: expected <$expected_target> actual <$actual_target>"
    mismatches=$((mismatches + 1))
  fi
done <<< "$old_links"
assert_equal "$mismatches" "0" "all targets match the original hardcoded array"

test_case "create_symlinks.sh no longer hardcodes a SYMLINKS array"
grep -q 'SYMLINKS=(' "$ROOT/common/create_symlinks.sh"
[ $? -ne 0 ]
assert_true $? "array is gone"

test_summary
