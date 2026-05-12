#Requires -Version 7
# Claude Code statusline — reads JSON from stdin, writes one line to stdout.
# Wire into ~/.claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "pwsh -NoProfile -File C:/Users/guinetik/Developer/gui-dotfiles/powershell/claude-statusline.ps1"
#   }

$raw = $input | Out-String
if (-not $raw.Trim()) { exit 0 }

try { $d = $raw | ConvertFrom-Json } catch { exit 0 }

$model    = $d.model.display_name ?? "claude"
$used     = [int]($d.context_window.total_input_tokens ?? 0)
$total    = [int]($d.context_window.context_window_size ?? 200000)
$pct      = if ($total -gt 0) { [int](($used / $total) * 100) } else { 0 }
$cost     = [math]::Round($d.cost.total_cost_usd ?? 0, 4)
$branch   = $d.workspace.git_branch ?? ""

function Format-Tokens([int]$n) {
    if ($n -ge 1000) { "$([math]::Round($n/1000, 1))k" } else { "$n" }
}

$barLen   = 10
$filled   = [int]([math]::Round($pct / 100 * $barLen))
$empty    = $barLen - $filled
$fill     = if ($pct -ge 80) { "!" } else { "#" }
$bar      = ($fill * $filled) + ("-" * $empty)

$usedFmt  = Format-Tokens $used
$totalFmt = Format-Tokens $total

$parts = @(
    "[$model]",
    "[$bar] $usedFmt/$totalFmt ($pct%)",
    "`$$cost"
)
if ($branch) { $parts += "($branch)" }

$parts -join "  "
