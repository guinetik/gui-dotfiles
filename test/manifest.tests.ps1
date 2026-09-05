#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\manifest.ps1"

$manifest = Join-Path $PSScriptRoot '..\windows\packages.json'

Test-Case 'flattens categories into entries' {
    $entries = Get-PackageManifest -Path $manifest
    Assert-True -Condition ($entries.Count -gt 10) -Message 'manifest has entries'
    Assert-True -Condition ($null -ne ($entries | Where-Object { $_.Name -eq 'ripgrep' })) -Message 'ripgrep present'
}

Test-Case 'every entry carries the three fields amh2w requires' {
    foreach ($entry in (Get-PackageManifest -Path $manifest)) {
        Assert-True -Condition ([bool]$entry.Name) -Message "name missing on an entry"
        Assert-True -Condition ([bool]$entry.Description) -Message "description missing on $($entry.Name)"
        Assert-True -Condition ([bool]$entry.Command) -Message "command missing on $($entry.Name)"
    }
}

Test-Case 'checkType defaults to command' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'ripgrep' }
    Assert-Equal -Actual $entry.CheckType -Expected 'command' -Message 'default checkType'
}

Test-Case 'ImageMagick probes magick, never convert' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'imagemagick' }
    Assert-Equal -Actual $entry.Check -Expected 'magick' -Message 'imagemagick check'
}

Test-Case 'no entry anywhere probes convert' {
    # C:\WINDOWS\system32\convert.exe is the NTFS filesystem converter and is
    # always present. Probing it reports ImageMagick as installed when it is not.
    $offenders = Get-PackageManifest -Path $manifest | Where-Object { $_.Check -eq 'convert' }
    Assert-Equal -Actual $offenders.Count -Expected 0 -Message 'no convert probes'
}

Test-Case 'entries with no check are provisioning steps' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'winget-upgrade' }
    Assert-True -Condition (-not $entry.Check) -Message 'winget-upgrade has no check'
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $false -Message 'no check means not a tool'
}

Test-Case 'detects an installed command' {
    $entry = [PSCustomObject]@{ Check = 'pwsh'; CheckType = 'command' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $true -Message 'pwsh is installed'
}

Test-Case 'detects a missing command' {
    $entry = [PSCustomObject]@{ Check = 'definitely-not-a-real-binary-xyz'; CheckType = 'command' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $false -Message 'missing tool'
}

Test-Case 'detects an installed module' {
    $entry = [PSCustomObject]@{ Check = 'PSReadLine'; CheckType = 'module' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $true -Message 'PSReadLine is installed'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
