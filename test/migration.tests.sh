#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Of the five files originally migrated out of gui-configs, only this one was
# kept. The owner dropped the rest after review:
#   windows/terminal/settings.json      266KB of stale machine state, linked by nothing
#   windows/scripts/fix-ssh-permissions.ps1  orphaned; published an SSH key path
#   windows/scripts/InstallFonts.ps1    orphaned; its font source stayed behind
#   common/install-wakatime.sh          sudo rm -rf on an unvalidated path, and
#                                       depended on a wakatime.cfg left behind
test_case "migrated files are present"
missing=0
for f in common/install-docker-compose.sh; do
  [ -f "$ROOT/$f" ] || { echo "    missing: $f"; missing=$((missing + 1)); }
done
assert_equal "$missing" "0" "all migrated files present"

test_case "dropped migrations stayed dropped"
present=0
for f in windows/terminal/settings.json \
         windows/scripts/fix-ssh-permissions.ps1 \
         windows/scripts/InstallFonts.ps1 \
         common/install-wakatime.sh; do
  [ -e "$ROOT/$f" ] && { echo "    unexpectedly present: $f"; present=$((present + 1)); }
done
assert_equal "$present" "0" "deliberately dropped files did not come back"

test_case "no key material came across"
hits=$(find "$ROOT" -type f \
        \( -name '*.asc' -o -name '*.pem' -o -name 'id_rsa*' -o -name '*firebase*.json' \) \
        -not -path '*/.git/*' | wc -l)
assert_equal "$hits" "0" "no key files in the repo"

test_case "no file staged for commit is ignored-worthy"
hits=$(git -C "$ROOT" ls-files | grep -cE '\.(asc|pem|ppk|p12|pfx)$|id_rsa|firebase.*\.json')
assert_equal "$hits" "0" "no tracked secrets"

# --- Content-based secret scan -------------------------------------------
# The filename check above is blind to a tracked file whose CONTENTS embed a
# live credential (e.g. a config file with a real token pasted into it).
# This scans tracked file contents for credential-shaped assignments with a
# real, non-placeholder value, plus private-key headers.
#
# KNOWN OFFENDERS: bash/.bashrc and zsh/.zshrc already carry a live Bitwarden
# access token and password, publicly, in git history. That is a real
# finding the repo owner is handling separately (rotation + history
# scrubbing) — this test does not rewrite history or touch those files.
# They are allowlisted below so the suite stays green while the rotation is
# pending; a match anywhere else fails the suite.
#
# MUST BE EMPTIED once the credentials in these files are rotated and the
# literal values are stripped from the working tree.
# EMPTIED 2026-09-05: bash/.bashrc and zsh/.zshrc were stripped of their
# GUINETIK_SERVER / GUINETIK_LOGIN / GUINETIK_PASSWORD / BWS_ACCESS_TOKEN
# exports, so they are now scanned like every other tracked file. The values
# remain in git history — history was deliberately not rewritten — which is why
# rotation, not stripping, was the actual fix. Keep this array empty.
KNOWN_SECRET_FILES=()

_migration_is_known_secret_file() {
  local f="$1" k
  for k in "${KNOWN_SECRET_FILES[@]}"; do
    [ "$f" = "$k" ] && return 0
  done
  return 1
}

# True if $1 looks like an empty value, a shell variable reference, or an
# obvious placeholder rather than a real pasted secret.
_migration_is_placeholder_value() {
  local v="$1"
  # Strip surrounding quote-ish noise, including the backslash-escaped
  # quotes seen in heredoc-generated scripts (e.g. \"$VAR\"), so a
  # reference like GUINETIK_PASSWORD=\"$GUINETIK_PASSWORD\" isn't mistaken
  # for a literal secret.
  while true; do
    case "$v" in
      \\\"*) v="${v#\\\"}" ;;
      \"*) v="${v#\"}" ;;
      \\\'*) v="${v#\\\'}" ;;
      \'*) v="${v#\'}" ;;
      *) break ;;
    esac
  done
  while true; do
    case "$v" in
      *\\\") v="${v%\\\"}" ;;
      *\") v="${v%\"}" ;;
      *\\\') v="${v%\\\'}" ;;
      *\') v="${v%\'}" ;;
      *) break ;;
    esac
  done
  [ -z "$v" ] && return 0
  # Unescape a backslash-escaped dollar sign (\$token, from heredoc'd
  # scripts) so it's recognized as a variable reference like $token.
  v="${v//\\\$/\$}"
  case "$v" in
    \$*|CHANGE_ME*|REPLACE_ME*|YOUR_*|your_*|TODO*|xxx*|XXX*|\<*\>) return 0 ;;
  esac
  return 1
}

test_case "no tracked file's CONTENTS hold a live credential"
assign_pattern='(^|[[:space:]])(BWS_ACCESS_TOKEN|[A-Za-z0-9_]*_(PASSWORD|API_KEY|SECRET|TOKEN))[[:space:]]*='
offenders=0
known_hits=0

while IFS= read -r f; do
  # grep -I skips files that look binary; -n gives line numbers.
  while IFS=: read -r lineno content; do
    [ -z "$lineno" ] && continue
    rhs="${content#*=}"
    rhs="${rhs#"${rhs%%[![:space:]]*}"}"   # trim leading whitespace
    if _migration_is_placeholder_value "$rhs"; then
      continue
    fi
    if _migration_is_known_secret_file "$f"; then
      known_hits=$((known_hits + 1))
      echo "    KNOWN (allowlisted, pending rotation): $f:$lineno"
    else
      offenders=$((offenders + 1))
      echo "    offender: $f:$lineno"
    fi
  done < <(grep -InE "$assign_pattern" -- "$ROOT/$f" 2>/dev/null)
done < <(git -C "$ROOT" ls-files)

# Private key headers, wherever they appear.
while IFS= read -r f; do
  while IFS=: read -r lineno content; do
    [ -z "$lineno" ] && continue
    if _migration_is_known_secret_file "$f"; then
      known_hits=$((known_hits + 1))
      echo "    KNOWN (allowlisted, pending rotation): $f:$lineno (private key header)"
    else
      offenders=$((offenders + 1))
      echo "    offender: $f:$lineno (private key header)"
    fi
  done < <(grep -InE 'BEGIN [A-Z ]*PRIVATE KEY' -- "$ROOT/$f" 2>/dev/null)
done < <(git -C "$ROOT" ls-files)

if [ "$known_hits" -gt 0 ]; then
  echo "    WARNING: $known_hits known-secret line(s) found in allowlisted files (bash/.bashrc, zsh/.zshrc)."
  echo "    WARNING: these credentials are live and public. Rotate them and empty KNOWN_SECRET_FILES."
fi
assert_equal "$offenders" "0" "no live credential content in tracked files outside the known allowlist"

# The Windows Terminal settings JSON-validity check lived here. It was dropped
# along with the file itself: 266KB of stale machine state that nothing linked
# and nothing installed. The "dropped migrations stayed dropped" case above is
# what now guards against it reappearing.
test_case "windows/packages.json is valid JSON"
WIN_ROOT="$(cygpath -w "$ROOT" 2>/dev/null || echo "$ROOT")"
pwsh -NoProfile -Command "Get-Content '$WIN_ROOT\windows\packages.json' -Raw | ConvertFrom-Json | Out-Null" 2>/dev/null
assert_true $? "packages.json parses (this is the file amh2w bootstrap consumes)"

test_summary
