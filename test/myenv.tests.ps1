#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\functions.ps1"

$manifest = Join-Path $PSScriptRoot '..\windows\packages.json'

Test-Case 'report excludes provisioning steps that have no check' {
    $report = Get-EnvReport -ManifestPath $manifest
    $offenders = $report | Where-Object { $_.Name -eq 'winget-upgrade' }
    Assert-Equal -Actual $offenders.Count -Expected 0 -Message 'winget-upgrade excluded'
}

Test-Case 'report marks an installed tool as installed' {
    $report = Get-EnvReport -ManifestPath $manifest
    $entry = $report | Where-Object { $_.Name -eq 'pwsh' }
    Assert-Equal -Actual $entry.Installed -Expected $true -Message 'pwsh detected'
}

Test-Case 'report preserves categories' {
    $report = Get-EnvReport -ManifestPath $manifest
    Assert-True -Condition (($report | Where-Object { $_.Category -eq 'cli' }).Count -gt 0) -Message 'cli category present'
}

Test-Case 'ImageMagick is not falsely reported via convert' {
    # Regression: C:\WINDOWS\system32\convert.exe always exists.
    $report = Get-EnvReport -ManifestPath $manifest
    $entry = $report | Where-Object { $_.Name -eq 'imagemagick' }
    $magickReal = [bool](Get-Command magick -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $entry.Installed -Expected $magickReal -Message 'tracks magick, not convert'
}

Test-Case 'rendered output has a line per reported tool' {
    $report = Get-EnvReport -ManifestPath $manifest
    $lines = Get-MyEnvLines -ManifestPath $manifest
    $marked = ($lines | Where-Object { $_ -match '✓' -or $_ -match '✗' }).Count
    Assert-Equal -Actual $marked -Expected $report.Count -Message 'one marked line per tool'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
