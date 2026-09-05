#Requires -Version 7
. "$PSScriptRoot\psv.ps1"

function Get-LinkPlan {
    param(
        [Parameter(Mandatory)][string]$LinksPath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $records = Read-PsvFile -Path $LinksPath
    foreach ($record in $records) {
        [PSCustomObject]@{
            Source = Join-Path $RepoRoot ($record.Key -replace '/', '\')
            Target = [Environment]::ExpandEnvironmentVariables($record.Values[0]) -replace '/', '\'
        }
    }
}

function Test-SafeToLink {
    <#
    .SYNOPSIS
        True when it is safe for the installer to place a symlink at $Target.
    .DESCRIPTION
        Never clobber a real file. `New-Item -Force` deletes whatever sits at
        the target, symlink or not - that is how an earlier version of the
        installer destroyed the user's ~/.claude/CLAUDE.md. Replacing our own
        symlink is fine; replacing a file someone actually wrote is not ours
        to do.

        Returns $true when the target is absent, or already a symlink.
        Returns $false when the target exists as a real file, hardlink, or
        directory/junction.
    #>
    param(
        [Parameter(Mandatory)][string]$Target
    )

    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $existing) { return $true }
    return $existing.LinkType -eq 'SymbolicLink'
}
