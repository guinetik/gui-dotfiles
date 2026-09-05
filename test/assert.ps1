#Requires -Version 7
# Minimal assert harness. No external dependencies on purpose: this repo
# bootstraps bare machines, so tests must run before anything is installed.

$script:Passed = 0
$script:Failed = 0

function Assert-Equal {
    param([Parameter(Mandatory)]$Actual, [Parameter(Mandatory)]$Expected, [string]$Message = '')
    if ($Actual -ne $Expected) {
        throw "Assert-Equal failed: $Message`n  expected: <$Expected>`n  actual:   <$Actual>"
    }
}

function Assert-True {
    param([Parameter(Mandatory)][bool]$Condition, [string]$Message = '')
    if (-not $Condition) { throw "Assert-True failed: $Message" }
}

function Assert-Throws {
    param([Parameter(Mandatory)][scriptblock]$ScriptBlock, [string]$Message = '')
    try { & $ScriptBlock } catch { return }
    throw "Assert-Throws failed: $Message (no exception was thrown)"
}

function Test-Case {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)
    try {
        & $Body
        $script:Passed++
        Write-Host "  PASS  $Name" -ForegroundColor Green
    } catch {
        $script:Failed++
        Write-Host "  FAIL  $Name" -ForegroundColor Red
        Write-Host "        $_" -ForegroundColor DarkRed
    }
}

function Get-TestSummary {
    [PSCustomObject]@{ Passed = $script:Passed; Failed = $script:Failed }
}
