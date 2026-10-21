#!/usr/bin/env bash
# macOS layer: link map, the symlinker's backup guard, and the Claude hooks.
# Nothing here needs macOS itself except the jq the hooks use.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "every mac link source exists in the repo"
missing=0
while IFS='|' read -r src target; do
  [ -e "$ROOT/$src" ] || { echo "    missing source: $src"; missing=$((missing + 1)); }
done < <(psv_filter "$ROOT/mac/links.psv")
assert_equal "$missing" "0" "no missing sources"

test_case "the mac map does not link a project file over the global CLAUDE.md"
psv_filter "$ROOT/mac/links.psv" | grep -q '^\.claude/CLAUDE\.md|'
[ $? -ne 0 ]
assert_true $? "no .claude/CLAUDE.md source"

test_case "mac/claude-settings.json is valid JSON"
jq empty "$ROOT/mac/claude-settings.json" 2>/dev/null
assert_true $? "settings parse"

test_case "symlinker moves real files and directories aside instead of clobbering"
fake_home="$(mktemp -d)"
map="$(mktemp)"
printf '%s\n' \
  'git/.gitconfig|$HOME/.gitconfig' \
  'ai/claude/skills|$HOME/.claude/skills' \
  'micro/settings.json|$HOME/.config/micro/settings.json' \
  'mac/claude-settings.json|$HOME/.claude/settings.json' > "$map"
mkdir -p "$fake_home/.claude/skills/synced" "$fake_home/.config/micro"
echo precious > "$fake_home/.gitconfig"
echo claude-local > "$fake_home/.claude/settings.json"
echo micro-local > "$fake_home/.config/micro/settings.json"
HOME="$fake_home" LINKS_FILE="$map" bash "$ROOT/common/create_symlinks.sh" >/dev/null 2>&1
[ -L "$fake_home/.gitconfig" ] && [ -L "$fake_home/.claude/skills" ]
assert_true $? "targets are now symlinks"
[ ! -e "$ROOT/ai/claude/skills/skills" ]
assert_true $? "directory link was not nested inside the old directory"
backup="$(ls -d "$fake_home"/.dotfiles-backup/* 2>/dev/null | head -1)"
assert_equal "$(cat "$backup/.gitconfig" 2>/dev/null)" "precious" "file backed up with its content"
[ -d "$backup/.claude/skills/synced" ]
assert_true $? "directory backed up whole"
assert_equal "$(cat "$backup/.claude/settings.json" 2>/dev/null)/$(cat "$backup/.config/micro/settings.json" 2>/dev/null)" \
  "claude-local/micro-local" "same-named files don't collide in the backup"
rm -rf "$fake_home" "$map"

test_case "statusline renders every widget from a full payload"
line=$(printf '%s' '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"/x/proj"},"context_window":{"total_input_tokens":130000,"context_window_size":200000},"cost":{"total_duration_ms":3720000}}' \
  | bash "$ROOT/mac/claude-statusline.sh" | sed 's/\x1b\[[0-9;]*m//g')
echo "$line" | grep -qF "Opus" && echo "$line" | grep -qF "proj" \
  && echo "$line" | grep -qF "130k/200k 65%" && echo "$line" | grep -qF "1h02m"
assert_true $? "model, folder, context and duration present: <$line>"

test_case "statusline goes amber past 60% and red past 80%"
amber=$(printf '%s' '{"context_window":{"total_input_tokens":130000,"context_window_size":200000}}' | bash "$ROOT/mac/claude-statusline.sh")
red=$(printf '%s' '{"context_window":{"total_input_tokens":170000,"context_window_size":200000}}' | bash "$ROOT/mac/claude-statusline.sh")
printf '%s' "$amber" | grep -q '38;2;255;184;0m█' && printf '%s' "$red" | grep -q '38;2;255;0;0m█'
assert_true $? "bar ink escalates"

test_case "statusline stays quiet on empty or broken input"
out=$(printf '' | bash "$ROOT/mac/claude-statusline.sh"); s1=$?
out2=$(printf 'not json' | bash "$ROOT/mac/claude-statusline.sh"); s2=$?
assert_equal "$s1$s2|$out$out2" "00|" "exit 0, no output"

test_case "notify skips the 60-second idle ping"
out=$(printf '%s' '{"message":"Claude is waiting for your input"}' | bash "$ROOT/mac/claude-notify.sh" ask --test)
echo "$out" | grep -q 'staying quiet' && ! echo "$out" | grep -q '^sound:'
assert_true $? "no sound for idle"

test_case "notify never fails a turn"
printf 'garbage' | bash "$ROOT/mac/claude-notify.sh" bogus >/dev/null 2>&1
assert_equal "$?" "0" "unknown trigger exits 0"

test_summary
