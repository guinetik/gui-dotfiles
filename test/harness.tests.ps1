#Requires -Version 7
. "$PSScriptRoot\assert.ps1"

Test-Case 'Assert-Equal passes on equal strings' {
    Assert-Equal -Actual 'a' -Expected 'a' -Message 'strings match'
}

Test-Case 'Assert-True passes on true' {
    Assert-True -Condition $true -Message 'true is true'
}

Test-Case 'Assert-Throws catches a throwing block' {
    Assert-Throws -ScriptBlock { throw 'boom' } -Message 'block throws'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
