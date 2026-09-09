#Requires -Version 7
# Claude Code statusline — reads JSON from stdin, writes one line to stdout.
#
#   󰚩 Opus 5 │  gui-dotfiles │  master │ [████████░░ 82k/200k 41%] │ 󰥔 24m
#
# Same phosphor-green palette and Nerd Font glyphs as starship/starship.toml,
# so the pinned statusline and the scrolling prompt read as one system.
# The context bar carries the warning: green under 60%, amber to 79%, red past
# that. No text says "you are running out of room" — the color does.
#
# Wire into ~/.claude/settings.json (not symlinked from this repo — see
# windows/links.psv for why):
#   "statusLine": {
#     "type": "command",
#     "command": "pwsh -NoProfile -File D:/Developer/gui-dotfiles/powershell/claude-statusline.ps1"
#   }

# Glyphs and block characters are non-ASCII; without this pwsh hands the host
# whatever the console codepage is and the bar arrives as mojibake.
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$raw = $input | Out-String
if (-not $raw.Trim()) { exit 0 }

try { $d = $raw | ConvertFrom-Json } catch { exit 0 }

# ─── palette (mirrors [palettes.vercel_phosphor] in starship.toml) ───────────
$RESET = "`e[0m"
function Ink([string]$hex, [string]$text) {
    $r = [Convert]::ToInt32($hex.Substring(1, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(3, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(5, 2), 16)
    "`e[38;2;$r;$g;${b}m$text$RESET"
}

# ─── Nerd Font glyphs, by codepoint ─────────────────────────────────────────
# Built from codepoints rather than pasted literals: the Private Use Area ones
# do not survive every editor/pipe they pass through, and the number says which
# glyph this is in a way the character never will.
$GLYPH_MODEL  = [char]::ConvertFromUtf32(0xF06A9)  # nf-md-robot
$GLYPH_CLOCK  = [char]::ConvertFromUtf32(0xF017)   # nf-fa-clock_o
$GLYPH_BRANCH = [char]::ConvertFromUtf32(0xE725)   # nf-dev-git_branch
$GLYPH_FOLDER = [char]::ConvertFromUtf32(0xF07B)   # nf-fa-folder

$PHOSPHOR_CORE   = '#00ff41'
$PHOSPHOR_BRIGHT = '#39ff14'
$PHOSPHOR_DIM    = '#00cc33'
$CYAN            = '#00e5ff'
$AMBER           = '#ffb800'
$RED             = '#ff0000'
$SALMON          = '#fa8072'
$ORANGE          = '#ff8c00'
$PINK            = '#ff69b4'

# ─── formatters ──────────────────────────────────────────────────────────────
function Format-Tokens([int]$n) {
    if ($n -ge 1000) { "$([math]::Round($n / 1000, 1))k" } else { "$n" }
}

function Format-Duration([double]$ms) {
    $s = [int]($ms / 1000)
    if ($s -ge 3600) { "{0}h{1:d2}m" -f [int]($s / 3600), [int](($s % 3600) / 60) }
    elseif ($s -ge 60) { "$([int]($s / 60))m" }
    else { "${s}s" }
}

# ─── fields (every one guarded — a missing key shortens the line, never breaks it)
$parts = @()

$model = $d.model.display_name ?? 'claude'
$parts += Ink $SALMON "$GLYPH_MODEL $model"

$cwd = $d.workspace.current_dir ?? $d.cwd ?? ''
if ($cwd) { $parts += Ink $CYAN "$GLYPH_FOLDER $(Split-Path $cwd -Leaf)" }

$branch = ''
if ($cwd) {
    $branch = (git -C $cwd branch --show-current 2>$null)
}
if ($branch) { $parts += Ink $ORANGE "$GLYPH_BRANCH $branch" }

$used  = [int]($d.context_window.total_input_tokens ?? 0)
$total = [int]($d.context_window.context_window_size ?? 200000)
if ($total -gt 0) {
    $pct     = [int](($used / $total) * 100)
    $barLen  = 10
    $filled  = [math]::Min($barLen, [int][math]::Round($pct / 100 * $barLen))
    $bar     = ('█' * $filled) + ('░' * ($barLen - $filled))
    # Green base, still escalating to amber/red as the window fills up --
    # the warning is worth more than strict adherence to "widget: green".
    $barInk  = if ($pct -ge 80) { $RED } elseif ($pct -ge 60) { $AMBER } else { $PHOSPHOR_CORE }
    $counts  = "$(Format-Tokens $used)/$(Format-Tokens $total) $pct%"
    # Bracketed so the bar+counts read as one widget, not two loose segments.
    $parts  += (Ink $PHOSPHOR_CORE '[') + (Ink $barInk $bar) + ' ' + (Ink $PHOSPHOR_CORE $counts) + (Ink $PHOSPHOR_CORE ']')
}

$durMs = [double]($d.cost.total_duration_ms ?? 0)
if ($durMs -gt 0) { $parts += Ink $PINK "$GLYPH_CLOCK $(Format-Duration $durMs)" }

$sep = Ink $PHOSPHOR_DIM ' │ '
$parts -join $sep
