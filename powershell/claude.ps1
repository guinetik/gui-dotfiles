#Requires -Version 7
<#
.SYNOPSIS
    Claude Code wrapper with sane defaults for Windows/PowerShell.
.DESCRIPTION
    Sets env vars, wires --dangerously-skip-permissions, and forwards all args.
    Load via gclaude in your profile:
        function gclaude { & "$env:DOTFILES\powershell\claude.ps1" @args }
#>

param()

$claudeBin = "$env:LOCALAPPDATA\..\Local\bin\claude.exe"
if (-not (Test-Path $claudeBin)) {
    $claudeBin = "$HOME\.local\bin\claude.exe"
}
if (-not (Test-Path $claudeBin)) {
    $claudeBin = (Get-Command claude -ErrorAction SilentlyContinue)?.Source
}
if (-not $claudeBin) {
    Write-Error "claude.exe not found. Expected at ~\.local\bin\claude.exe"
    exit 1
}

$env:CLAUDE_CODE_NO_FLICKER        = "1"
$env:CLAUDE_CODE_USE_POWERSHELL_TOOL = "1"

& $claudeBin --dangerously-skip-permissions @args
