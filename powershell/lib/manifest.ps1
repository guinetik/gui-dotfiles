#Requires -Version 7
# Reads the amh2w-compatible package manifest and probes what is installed.
# Detection is always live: nothing here caches a result.

function Get-PackageManifest {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Package manifest not found: $Path"
    }

    $json = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $entries = @()

    foreach ($category in $json.PSObject.Properties) {
        foreach ($package in $category.Value) {
            $checkType = if ($package.PSObject.Properties.Name -contains 'checkType' -and $package.checkType) {
                $package.checkType
            } else {
                'command'
            }
            $entries += [PSCustomObject]@{
                Category    = $category.Name
                Name        = $package.name
                Description = $package.description
                Command     = $package.command
                Check       = $package.check
                CheckType   = $checkType
            }
        }
    }
    # Returned WITHOUT the array-preserving comma (cf. psv.ps1): Get-EnvReport
    # pipes this result through Where-Object/ForEach-Object, and `return ,$x`
    # would hand the pipeline the whole array as a single item.
    return $entries
}

function Test-ToolInstalled {
    param([Parameter(Mandatory)][PSCustomObject]$Entry)

    if (-not $Entry.Check) { return $false }

    if ($Entry.CheckType -eq 'module') {
        return [bool](Get-Module -ListAvailable -Name $Entry.Check -ErrorAction SilentlyContinue)
    }
    return [bool](Get-Command $Entry.Check -ErrorAction SilentlyContinue)
}
