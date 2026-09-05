#Requires -Version 7
$failed = 0
foreach ($file in (Get-ChildItem -Path $PSScriptRoot -Filter '*.tests.ps1' | Sort-Object Name)) {
    Write-Host "`n=== $($file.Name) ===" -ForegroundColor Cyan
    pwsh -NoProfile -File $file.FullName
    if ($LASTEXITCODE -ne 0) { $failed++ }
}
if ($failed -gt 0) {
    Write-Host "`n$failed test file(s) failed" -ForegroundColor Red
    exit 1
}
Write-Host "`nAll test files passed" -ForegroundColor Green
