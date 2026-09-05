#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\functions.ps1"

$psv = Join-Path $PSScriptRoot '..\tradecraft.psv'

Test-Case 'renders the title into the top border' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition ($lines[0] -match 'Tradecraft: Working with guinetik') -Message 'title rendered'
}

Test-Case 'renders every bullet from the data file' {
    $lines = Get-TradecraftLines -Path $psv
    $records = Read-PsvFile -Path $psv
    $bulletCount = ($records | Where-Object { $_.Key -eq '-' }).Count
    $rendered = ($lines | Where-Object { $_ -match '✓' }).Count
    Assert-Equal -Actual $rendered -Expected $bulletCount -Message 'one rendered line per bullet'
}

Test-Case 'never mentions the nonexistent tour command' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition (-not ($lines -match "'tour'")) -Message 'tour is gone'
}

Test-Case 'describes Windows as the daily driver' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition (($lines -match 'Windows 11 native').Count -gt 0) -Message 'ecosystem is current'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
