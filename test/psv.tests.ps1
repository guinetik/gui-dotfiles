#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\psv.ps1"

$fixture = Join-Path ([System.IO.Path]::GetTempPath()) "psv-test-$PID.psv"
@'
# a comment line
@section|Modern CLI Tools

eza|Enhanced ls - colorful listing
imagemagick|Image toolkit|magick
'@ | Set-Content -LiteralPath $fixture -Encoding utf8

Test-Case 'skips comments and blank lines' {
    $records = Read-PsvFile -Path $fixture
    Assert-Equal -Actual $records.Count -Expected 3 -Message 'three real records'
}

Test-Case 'splits key from values' {
    $records = Read-PsvFile -Path $fixture
    Assert-Equal -Actual $records[0].Key -Expected '@section' -Message 'first key'
    Assert-Equal -Actual $records[0].Values[0] -Expected 'Modern CLI Tools' -Message 'first value'
}

Test-Case 'keeps every field after the first' {
    $records = Read-PsvFile -Path $fixture
    Assert-Equal -Actual $records[2].Values.Count -Expected 2 -Message 'two values'
    Assert-Equal -Actual $records[2].Values[1] -Expected 'magick' -Message 'third field'
}

Test-Case 'throws on a missing file' {
    Assert-Throws -ScriptBlock { Read-PsvFile -Path 'X:\nope\missing.psv' } -Message 'missing file'
}

Remove-Item -LiteralPath $fixture -Force

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
