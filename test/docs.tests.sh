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

test_case "both CLAUDE.md files name the same commands"
root_cmds=$(grep -o 'myenv\|tradecraft' "$ROOT/CLAUDE.md" | sort -u | tr '\n' ' ')
claude_cmds=$(grep -o 'myenv\|tradecraft' "$ROOT/.claude/CLAUDE.md" | sort -u | tr '\n' ' ')
assert_equal "$root_cmds" "$claude_cmds" "vocabularies match"

test_case "every backtick-quoted repo path in the CLAUDE.md files exists"
# Candidate: a backtick-quoted token that looks like a repo-relative path -
# it contains a '/' or ends in a doc/script/data extension we ship.
# Excluded: bare command names (myenv, tradecraft - no slash, no matching
# extension), anything with a space or shell glob character, and anything
# starting with '~' or '$' (not repo-relative).
missing_paths=""
checked=0
for docfile in "$ROOT/CLAUDE.md" "$ROOT/.claude/CLAUDE.md"; do
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    case "$token" in
      *' '*|*'*'*|*'?'*|*'['*|*']'*|'~'*|'$'*) continue ;;
    esac
    case "$token" in
      */*|*.md|*.sh|*.ps1|*.json|*.psv) : ;;
      *) continue ;;
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
