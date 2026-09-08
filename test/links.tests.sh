#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "every link source exists in the repo"
missing=0
while IFS='|' read -r src target; do
  # -e not -f: ai/claude/skills and ai/claude/commands are directory sources.
  [ -e "$ROOT/$src" ] || { echo "    missing source: $src"; missing=$((missing + 1)); }
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
# Eight of the original nine pairs, unchanged. The ninth,
# `.claude/CLAUDE.md:$HOME/.claude/CLAUDE.md`, was deliberately removed: it
# linked this repo's PROJECT context file over the user's GLOBAL Claude Code
# instruction file. Two different documents; conflating them destroyed the
# global one on Windows. The project file has since been folded into the root
# CLAUDE.md and deleted, and the global one lives at ai/claude/CLAUDE.md.
old_links="bash/.bashrc:\$HOME/.bashrc
zsh/.zshrc:\$HOME/.zshrc
zsh/.zshenv:\$HOME/.zshenv
zsh/.zsh_plugins.txt:\$HOME/.zsh_plugins.txt
shell/aliases.sh:\$HOME/.config/shell/aliases.sh
shell/functions.sh:\$HOME/.config/shell/functions.sh
starship/starship.toml:\$HOME/.config/starship.toml
git/.gitconfig:\$HOME/.gitconfig"

# Deliberate additions since the extraction. Listed explicitly for the same
# reason as the golden values above: these decide where files land in someone's
# home directory, so growing the map should be a visible edit, not a silent one.
new_links="ai/claude/CLAUDE.md:\$HOME/.claude/CLAUDE.md
ai/claude/skills:\$HOME/.claude/skills
ai/claude/commands:\$HOME/.claude/commands
linux/claude-settings.json:\$HOME/.claude/settings.json"

test_case "link map holds exactly the expected pairs"
expected_count=$(printf '%s\n%s\n' "$old_links" "$new_links" | grep -c .)
actual_count=$(psv_filter "$ROOT/linux/links.psv" | wc -l)
assert_equal "$actual_count" "$expected_count" "link count matches golden + added pairs"

test_case "every added link target is correct"
added_mismatches=0
while IFS=':' read -r src expected_target; do
  [ -z "$src" ] && continue
  actual_target=$(psv_filter "$ROOT/linux/links.psv" | awk -F'|' -v s="$src" '$1==s{print $2}')
  if [ "$actual_target" != "$expected_target" ]; then
    echo "    target mismatch for $src: expected <$expected_target> actual <$actual_target>"
    added_mismatches=$((added_mismatches + 1))
  fi
done <<< "$new_links"
assert_equal "$added_mismatches" "0" "added targets match"

test_case "the repo no longer links a project file over the global CLAUDE.md"
psv_filter "$ROOT/linux/links.psv" | grep -q '^\.claude/CLAUDE\.md|'
[ $? -ne 0 ]
assert_true $? "the destructive .claude/CLAUDE.md link is gone"

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
