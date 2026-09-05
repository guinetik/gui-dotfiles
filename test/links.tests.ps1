#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\links.ps1"

$fixture = Join-Path ([System.IO.Path]::GetTempPath()) "links-test-$PID.psv"
@'
# comment
powershell/dotfiles.ps1|%USERPROFILE%/Documents/PowerShell/drop-ins/00-gui-dotfiles.ps1
windows/terminal/settings.json|%LOCALAPPDATA%/Test/settings.json
'@ | Set-Content -LiteralPath $fixture -Encoding utf8

Test-Case 'source becomes an absolute repo path with backslashes' {
    $plan = Get-LinkPlan -LinksPath $fixture -RepoRoot 'D:\Developer\gui-dotfiles'
    Assert-Equal -Actual $plan[0].Source -Expected 'D:\Developer\gui-dotfiles\powershell\dotfiles.ps1' -Message 'source path'
}

Test-Case 'target expands environment variables' {
    $plan = Get-LinkPlan -LinksPath $fixture -RepoRoot 'D:\Developer\gui-dotfiles'
    Assert-True -Condition (-not ($plan[0].Target -match '%USERPROFILE%')) -Message 'no unexpanded variable'
    Assert-True -Condition ($plan[0].Target -match 'drop-ins') -Message 'target path preserved'
}

Test-Case 'multi-record fixture parses each record independently' {
    $plan = Get-LinkPlan -LinksPath $fixture -RepoRoot 'D:\Developer\gui-dotfiles'
    Assert-Equal -Actual $plan.Count -Expected 2 -Message 'plan has one entry per record'
    Assert-Equal -Actual $plan[0].Source -Expected 'D:\Developer\gui-dotfiles\powershell\dotfiles.ps1' -Message 'record 1 source'
    Assert-Equal -Actual $plan[0].Target -Expected "$env:USERPROFILE\Documents\PowerShell\drop-ins\00-gui-dotfiles.ps1" -Message 'record 1 target'
    Assert-Equal -Actual $plan[1].Source -Expected 'D:\Developer\gui-dotfiles\windows\terminal\settings.json' -Message 'record 2 source'
    Assert-Equal -Actual $plan[1].Target -Expected "$env:LOCALAPPDATA\Test\settings.json" -Message 'record 2 target'
}

Test-Case 'real links file parses and points every source at a file that exists' {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
    $plan = Get-LinkPlan -LinksPath (Join-Path $repoRoot 'windows\links.psv') -RepoRoot $repoRoot
    Assert-True -Condition ($plan.Count -gt 0) -Message 'plan is not empty'
    foreach ($link in $plan) {
        Assert-True -Condition (Test-Path -LiteralPath $link.Source) -Message "source missing: $($link.Source)"
    }
}

Remove-Item -LiteralPath $fixture -Force

# --- Test-SafeToLink -------------------------------------------------------
# Extracted from install.ps1's clobber guard (added after it destroyed a
# user's ~/.claude/CLAUDE.md). Every fixture lives under its own mktemp-style
# scratch directory and is cleaned up afterward.
$scratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) "links-safe-test-$PID"
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

Test-Case 'Test-SafeToLink: absent target is safe' {
    $target = Join-Path $scratchRoot 'does-not-exist.txt'
    Assert-True -Condition (Test-SafeToLink -Target $target) -Message 'absent target is safe to link'
}

Test-Case 'Test-SafeToLink: existing symlink is safe' {
    $linkTarget = Join-Path $scratchRoot 'link-target.txt'
    Set-Content -LiteralPath $linkTarget -Value 'target' -Encoding utf8
    $linkPath = Join-Path $scratchRoot 'existing-symlink.txt'
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $linkTarget -Force | Out-Null
    Assert-True -Condition (Test-SafeToLink -Target $linkPath) -Message 'existing symlink is safe to replace'
}

Test-Case 'Test-SafeToLink: real file is not safe' {
    $realFile = Join-Path $scratchRoot 'real-file.txt'
    Set-Content -LiteralPath $realFile -Value 'do not delete me' -Encoding utf8
    Assert-True -Condition (-not (Test-SafeToLink -Target $realFile)) -Message 'real file is refused'
}

Test-Case 'Test-SafeToLink: real directory is not safe' {
    $realDir = Join-Path $scratchRoot 'real-dir'
    New-Item -ItemType Directory -Path $realDir -Force | Out-Null
    Assert-True -Condition (-not (Test-SafeToLink -Target $realDir)) -Message 'real directory is refused'
}

Remove-Item -LiteralPath $scratchRoot -Recurse -Force

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
