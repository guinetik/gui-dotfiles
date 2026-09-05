#Requires -Version 7
# myenv and tradecraft for Windows. Bare names on purpose: they match the
# bash functions in shell/functions.sh and the muscle memory that goes with them.

. "$PSScriptRoot\lib\psv.ps1"
. "$PSScriptRoot\lib\render.ps1"
. "$PSScriptRoot\lib\manifest.ps1"

function Get-DotfilesRoot {
    if ($env:DOTFILES -and (Test-Path -LiteralPath $env:DOTFILES)) { return $env:DOTFILES }
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-TradecraftLines {
    param([string]$Path = (Join-Path (Get-DotfilesRoot) 'tradecraft.psv'))

    $records = Read-PsvFile -Path $Path
    $lines = @()
    $tips = @()

    foreach ($record in $records) {
        switch ($record.Key) {
            '@title'   { $lines += Format-BoxTop -Title $record.Values[0]; $lines += Format-BoxLine }
            '@section' { $lines += Format-BoxSection -Title $record.Values[0]; $lines += Format-BoxLine }
            '-'        { $lines += Format-BoxItem -Text $record.Values[0] -Marker '✓' }
            '@tip'     { $tips += $record.Values[0] }
        }
    }

    $lines += Format-BoxLine
    $lines += Format-BoxBottom
    if ($tips.Count -gt 0) {
        $lines += ''
        $lines += Format-TipHeader -Text '💡 Work effectively by:'
        foreach ($tip in $tips) { $lines += Format-Tip -Text $tip }
    }
    return $lines
}

function tradecraft {
    Write-Host ''
    Get-TradecraftLines | ForEach-Object { Write-Host $_ }
    Write-Host ''
}

function Get-EnvReport {
    param([string]$ManifestPath = (Join-Path (Get-DotfilesRoot) 'windows\packages.json'))

    Get-PackageManifest -Path $ManifestPath |
        Where-Object { $_.Check } |
        ForEach-Object {
            [PSCustomObject]@{
                Category    = $_.Category
                Name        = $_.Name
                Description = $_.Description
                Installed   = (Test-ToolInstalled -Entry $_)
            }
        }
}

function Get-MyEnvLines {
    param([string]$ManifestPath = (Join-Path (Get-DotfilesRoot) 'windows\packages.json'))

    $report = Get-EnvReport -ManifestPath $ManifestPath
    $lines = @(Format-BoxTop -Title 'My Environment (myenv)')
    $lines += Format-BoxLine

    foreach ($group in ($report | Group-Object Category)) {
        $lines += Format-BoxSection -Title $group.Name
        $lines += Format-BoxLine
        foreach ($tool in $group.Group) {
            $marker = if ($tool.Installed) { '✓' } else { '✗' }
            $color  = if ($tool.Installed) { 'green' } else { 'red' }
            $lines += Format-BoxItem -Text "$($tool.Name) - $($tool.Description)" -Marker $marker -Color $color
        }
        $lines += Format-BoxLine
    }

    $lines += Format-BoxBottom
    $missing = ($report | Where-Object { -not $_.Installed }).Count
    if ($missing -gt 0) {
        $lines += ''
        $lines += Format-Tip -Text "$missing tool(s) missing. Install with: all my homies bootstrap `"$(Get-DotfilesRoot)\windows\packages.json`""
    }
    return $lines
}

function myenv {
    Write-Host ''
    Get-MyEnvLines | ForEach-Object { Write-Host $_ }
    Write-Host ''
}
