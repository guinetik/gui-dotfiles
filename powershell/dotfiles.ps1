#Requires -Version 7
# Profile drop-in. Symlinked into Documents\PowerShell\drop-ins\ so the repo
# stays the source of truth: edits here take effect in the next shell.

# Derive the repo root from this script's own location instead of a
# hardcoded path, so a clone anywhere other than D:\Developer\gui-dotfiles
# doesn't get $env:DOTFILES silently overwritten with a bogus value on
# every shell start (install.ps1 persists the correct value; this file
# must not clobber it).
#
# Subtlety: this file is a SYMLINK (Documents\PowerShell\drop-ins\... ->
# repo\powershell\dotfiles.ps1). $PSScriptRoot on a symlinked script
# resolves to the LINK's directory, not the repo, so we resolve the link's
# .Target instead. When the script is NOT a symlink (e.g. dot-sourced
# directly from the repo while editing), .Target is empty and we fall back
# to $PSScriptRoot's parent.
$scriptItem = Get-Item -LiteralPath $PSCommandPath
$repoRoot = if ($scriptItem.Target) {
    Split-Path -Parent (Split-Path -Parent $scriptItem.Target)
} else {
    Split-Path -Parent $PSScriptRoot
}

$env:DOTFILES = $repoRoot
if (Test-Path -LiteralPath "$env:DOTFILES\powershell\functions.ps1") {
    . "$env:DOTFILES\powershell\functions.ps1"
}
