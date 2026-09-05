#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "the nonexistent 'tour' command is referenced nowhere"
# docs/ is excluded: the spec and this plan discuss 'tour' by name.
# .superpowers/ is excluded: it holds task briefs extracted verbatim from the
# plan (including this task's own text), not shipped dotfiles.
hits=$(grep -rn '\btour\b' "$ROOT" \
        --exclude-dir=.git --exclude-dir=docs --exclude-dir=test --exclude-dir=.superpowers 2>/dev/null | wc -l)
assert_equal "$hits" "0" "no tour references"

test_case "a gitignore exists"
[ -f "$ROOT/.gitignore" ]
assert_true $? "gitignore present"

test_case "gitignore blocks key material"
missing=0
for pattern in '*.asc' '*.pem' 'id_rsa*' '*.env' '*secret*' '*credential*'; do
  grep -qF "$pattern" "$ROOT/.gitignore" || { echo "    missing: $pattern"; missing=$((missing + 1)); }
done
assert_equal "$missing" "0" "all secret patterns present"

test_case "git actually ignores a dropped private key"
touch "$ROOT/test-fixture.pem"
git -C "$ROOT" check-ignore -q test-fixture.pem
result=$?
rm -f "$ROOT/test-fixture.pem"
assert_true "$result" "pem file is ignored"

# There used to be two CLAUDE.md files with overlapping content — the root one
# (project guide) and .claude/CLAUDE.md (working preferences) — and a test that
# they at least agreed on command names. The second has been folded into
# ai/claude/CLAUDE.md, the global instruction file this repo symlinks to
# ~/.claude/CLAUDE.md, and deleted. One document per audience, so there is no
# longer a vocabulary to reconcile.
test_case "the merged project file did not lose the commands it documents"
missing_cmds=0
for cmd in myenv tradecraft; do
  grep -q "$cmd" "$ROOT/CLAUDE.md" || { echo "    root CLAUDE.md no longer mentions: $cmd"; missing_cmds=$((missing_cmds + 1)); }
  grep -q "$cmd" "$ROOT/ai/claude/CLAUDE.md" || { echo "    ai/claude/CLAUDE.md no longer mentions: $cmd"; missing_cmds=$((missing_cmds + 1)); }
done
assert_equal "$missing_cmds" "0" "both surviving docs still name myenv and tradecraft"

test_case "the deleted project context file is really gone"
[ ! -e "$ROOT/.claude/CLAUDE.md" ]
assert_true $? ".claude/CLAUDE.md removed"

test_case "every backtick-quoted repo path in the CLAUDE.md files exists"
# Candidate: a backtick-quoted token that looks like a repo-relative path, which
# means it has a DIRECTORY COMPONENT - a '/' that is not the last character.
#
# Requiring the slash is what keeps this honest. An earlier version also accepted
# any bare token ending in a shipped extension, which flagged `settings.json`
# (Claude Code's settings, not a file in this repo) and `tmp/`, `var/`
# (hypothetical scratch dirs at whatever project root you happen to be in). Those
# are generic references, not links into this repo, and a test that cries wolf
# about them gets deleted by the next person who trips over it.
#
# Excluded: bare command names (myenv, tradecraft), trailing-slash directory
# placeholders, anything with a space or shell glob character, and anything
# starting with '~' or '$' (not repo-relative).
missing_paths=""
checked=0
for docfile in "$ROOT/CLAUDE.md" "$ROOT/ai/claude/CLAUDE.md"; do
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    case "$token" in
      *' '*|*'*'*|*'?'*|*'['*|*']'*|'~'*|'$'*) continue ;;
    esac
    case "$token" in
      */) continue ;;      # trailing slash: a directory placeholder like tmp/
      */*) : ;;            # has a directory component: treat as a repo path
      *) continue ;;       # bare token: not a repo-relative path
    esac
    checked=$((checked + 1))
    if [ ! -e "$ROOT/$token" ]; then
      missing_paths="$missing_paths $token"
    fi
  done < <(grep -oE '`[^`]+`' "$docfile" | sed -E 's/^`//; s/`$//')
done
if [ -n "$missing_paths" ]; then
  echo "    missing:$missing_paths"
fi
assert_equal "$missing_paths" "" "all referenced paths exist ($checked checked)"

test_summary
