#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\render.ps1"

Test-Case 'box top contains the title' {
    Assert-True -Condition ((Format-BoxTop -Title 'Hello') -match 'Hello') -Message 'title present'
}

Test-Case 'box top is bounded by corner glyphs' {
    $top = Format-BoxTop -Title 'Hello'
    Assert-True -Condition ($top -match '╭') -Message 'has top-left corner'
    Assert-True -Condition ($top -match '╮') -Message 'has top-right corner'
}

Test-Case 'box line carries the text and a left border' {
    $line = Format-BoxLine -Text 'some text'
    Assert-True -Condition ($line -match 'some text') -Message 'text present'
    Assert-True -Condition ($line -match '│') -Message 'left border present'
}

Test-Case 'box item carries its marker and text' {
    $item = Format-BoxItem -Text 'eza - better ls' -Marker '✓'
    Assert-True -Condition ($item -match '✓') -Message 'marker present'
    Assert-True -Condition ($item -match 'eza - better ls') -Message 'text present'
}

Test-Case 'box bottom has the closing corners' {
    $bottom = Format-BoxBottom
    Assert-True -Condition ($bottom -match '╰') -Message 'has bottom-left corner'
    Assert-True -Condition ($bottom -match '╯') -Message 'has bottom-right corner'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
