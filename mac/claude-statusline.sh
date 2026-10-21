#!/usr/bin/env bash
# Claude Code statusline for macOS — reads JSON from stdin, writes one line.
# Port of powershell/claude-statusline.ps1; keep the two in step.
#
#   󰚩 Opus 5 │  gui-dotfiles │  master │ [████████░░ 82k/200k 41%] │ 󰥔 24m
#
# Same phosphor palette and Nerd Font glyphs as starship/starship.toml. The
# context bar carries the warning: green under 60%, amber to 79%, red past it.
#
# bash 3.2 on purpose (it's what /bin/bash is on macOS) and jq from /usr/bin,
# so this works on a bare machine before brew has installed anything.

raw="$(cat)"
[ -n "${raw//[[:space:]]/}" ] || exit 0

# One jq pass. Unit separator rather than tab: tab is IFS whitespace, so empty
# fields would collapse and shift everything after them.
US=$'\x1f'
fields="$(printf '%s' "$raw" | jq -r --arg us "$US" '[
  (.model.display_name // "claude"),
  (.workspace.current_dir // .cwd // ""),
  ((.context_window.total_input_tokens // 0) | tostring),
  ((.context_window.context_window_size // 200000) | tostring),
  ((.cost.total_duration_ms // 0) | floor | tostring)
] | join($us)' 2>/dev/null)" || exit 0
IFS="$US" read -r model cwd used total dur_ms <<< "$fields"

# ─── palette (mirrors [palettes.vercel_phosphor] in starship.toml) ───────────
RESET=$'\e[0m'
ink() { # ink '#rrggbb' text
  local hex="${1#\#}"
  printf '\e[38;2;%d;%d;%dm%s%s' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}" "$2" "$RESET"
}
PHOSPHOR_CORE='#00ff41'
PHOSPHOR_DIM='#00cc33'
CYAN='#00e5ff'
AMBER='#ffb800'
RED='#ff0000'
SALMON='#fa8072'
ORANGE='#ff8c00'
PINK='#ff69b4'

# ─── Nerd Font glyphs, as UTF-8 bytes ───────────────────────────────────────
# bash 3.2 has no \U escape, so the codepoints are spelled out as bytes.
GLYPH_MODEL=$'\xf3\xb0\x9a\xa9'   # U+F06A9 nf-md-robot
GLYPH_CLOCK=$'\xef\x80\x97'       # U+F017  nf-fa-clock_o
GLYPH_BRANCH=$'\xee\x9c\xa5'      # U+E725  nf-dev-git_branch
GLYPH_FOLDER=$'\xef\x81\xbb'      # U+F07B  nf-fa-folder

# ─── formatters ──────────────────────────────────────────────────────────────
fmt_tokens() {
  if [ "$1" -ge 1000 ]; then
    awk -v n="$1" 'BEGIN { s = sprintf("%.1f", n / 1000); sub(/\.0$/, "", s); print s "k" }'
  else
    printf '%s' "$1"
  fi
}

fmt_duration() {
  local s=$(( $1 / 1000 ))
  if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $(( s / 3600 )) $(( (s % 3600) / 60 ))
  elif [ "$s" -ge 60 ]; then printf '%dm' $(( s / 60 ))
  else printf '%ds' "$s"
  fi
}

# ─── fields (each guarded — a missing key shortens the line, never breaks it)
parts=()
parts+=("$(ink "$SALMON" "$GLYPH_MODEL $model")")

if [ -n "$cwd" ]; then
  parts+=("$(ink "$CYAN" "$GLYPH_FOLDER ${cwd##*/}")")
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
  [ -n "$branch" ] && parts+=("$(ink "$ORANGE" "$GLYPH_BRANCH $branch")")
fi

if [ "${total:-0}" -gt 0 ] 2>/dev/null; then
  pct=$(( used * 100 / total ))
  filled=$(( (pct * 10 + 50) / 100 ))
  [ "$filled" -gt 10 ] && filled=10
  bar=""
  i=0
  while [ "$i" -lt 10 ]; do
    if [ "$i" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
    i=$(( i + 1 ))
  done
  if [ "$pct" -ge 80 ]; then bar_ink="$RED"
  elif [ "$pct" -ge 60 ]; then bar_ink="$AMBER"
  else bar_ink="$PHOSPHOR_CORE"
  fi
  counts="$(fmt_tokens "$used")/$(fmt_tokens "$total") ${pct}%"
  parts+=("$(ink "$PHOSPHOR_CORE" '[')$(ink "$bar_ink" "$bar") $(ink "$PHOSPHOR_CORE" "$counts")$(ink "$PHOSPHOR_CORE" ']')")
fi

if [ "${dur_ms:-0}" -gt 0 ] 2>/dev/null; then
  parts+=("$(ink "$PINK" "$GLYPH_CLOCK $(fmt_duration "$dur_ms")")")
fi

sep="$(ink "$PHOSPHOR_DIM" ' │ ')"
out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$p"; else out="$out$sep$p"; fi
done
printf '%s\n' "$out"
