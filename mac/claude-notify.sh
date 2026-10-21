#!/usr/bin/env bash
# Claude Code hook for macOS: potion sound + notification when Claude wants you.
# Port of powershell/claude-notify.ps1 — read that file's header for the full
# reasoning; the short version:
#
#   ask   Claude is blocked on a question or permission  -> small potion
#   done  Claude finished the turn                       -> big potion
#
#   sound   afplay, detached. Ships with macOS, plays mp3 natively.
#   toast   osascript `display notification`. Shows up attributed to Script
#           Editor; allow it once in System Settings > Notifications.
#           The subtitle names the conversation (its /rename'd title from
#           ~/.claude/sessions/*.json, else the project folder).
#
# There is no taskbar-flash equivalent: a hook has no handle on the terminal
# window, and the dock-bounce APIs need an app bundle.
#
# Idle filter: the Notification hook also fires after 60s of an untouched
# input box ("Claude is waiting for your input"). That one stays quiet.
# Everything else fails open — a missed notification beats a spurious one —
# and the script always exits 0 so it can never fail a turn.
#
# Usage:  claude-notify.sh ask|done [--test]
#   --test  print what was found, so a hand-run shows which signals are live
# Set CLAUDE_NOTIFY_LOG to a file path to record every invocation.

trigger="$1"
test_mode=""
[ "$2" = "--test" ] && test_mode=1
diag() { [ -n "$test_mode" ] && printf '%s\n' "$*"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOUNDS="$ROOT/ai/claude/sounds"

case "$trigger" in
  ask)
    sound="$SOUNDS/PrinceOfPersiaSNESPotion.mp3"
    title='Claude is waiting'
    body='A question or a permission prompt needs you.'
    ;;
  done)
    sound="$SOUNDS/PrinceOfPersiaSNESBigPotion.mp3"
    title='Claude is done'
    body='The turn finished. Nothing is blocked.'
    ;;
  *)
    echo "usage: $0 ask|done [--test]" >&2
    exit 0
    ;;
esac

# ─── parse the hook payload ──────────────────────────────────────────────────
# The -t guard keeps a hand-run from blocking on an interactive terminal.
message='' session_id='' cwd=''
if [ ! -t 0 ]; then
  raw="$(cat)"
  if [ -n "$raw" ]; then
    message="$(printf '%s' "$raw" | jq -r '.message // ""' 2>/dev/null)"
    session_id="$(printf '%s' "$raw" | jq -r '.session_id // ""' 2>/dev/null)"
    cwd="$(printf '%s' "$raw" | jq -r '.cwd // ""' 2>/dev/null)"
  fi
fi
diag "payload: message=[$message] session_id=[$session_id] cwd=[$cwd]"

# ─── which conversation ──────────────────────────────────────────────────────
label=''
if [ -n "$session_id" ]; then
  for f in "$HOME"/.claude/sessions/*.json; do
    [ -f "$f" ] || continue
    label="$(jq -r --arg id "$session_id" 'select(.sessionId == $id) | .name // empty' "$f" 2>/dev/null)"
    [ -n "$label" ] && break
  done
fi
[ -z "$label" ] && [ -n "$cwd" ] && label="${cwd##*/}"
diag "label: [$label]"

# ─── idle filter ─────────────────────────────────────────────────────────────
idle=''
if [ "$trigger" = ask ] && printf '%s' "$message" | grep -q 'waiting for your input'; then
  idle=1
fi

if [ -n "$CLAUDE_NOTIFY_LOG" ]; then
  printf '%s trigger=%s%s pid=%s ppid=%s msg="%s"\n' \
    "$(date +%H:%M:%S)" "$trigger" "${idle:+ SKIPPED(idle)}" "$$" "$PPID" \
    "$(printf '%s' "$message" | tr -s '[:space:]' ' ')" >> "$CLAUDE_NOTIFY_LOG" 2>/dev/null
fi

if [ -n "$idle" ]; then
  diag 'idle notification, staying quiet'
  exit 0
fi

# ─── 1. sound ────────────────────────────────────────────────────────────────
# Subshell + closed fds: the hook must return now, not when the potion ends.
if [ -f "$sound" ]; then
  ( afplay "$sound" </dev/null >/dev/null 2>&1 & )
  diag "sound: afplay $sound"
else
  diag "sound: missing $sound, skipping"
fi

# ─── 2. notification ─────────────────────────────────────────────────────────
# Text goes in as argv, never spliced into the script: the label comes from a
# session name and could contain quotes.
osascript - "$title" "$label" "$body" >/dev/null 2>&1 <<'APPLESCRIPT' && diag 'toast: sent' || diag 'toast: failed'
on run argv
  display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv)
end run
APPLESCRIPT

exit 0
