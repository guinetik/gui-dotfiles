#Requires -Version 7
# Pipe-delimited record parsing. Chosen over JSON because bash reads this
# format with `IFS='|' read` and no jq dependency; PowerShell reads it here.

function Read-PsvFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "PSV file not found: $Path"
    }

    $records = @()
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }

        $parts = $trimmed -split '\|'
        $values = @(for ($i = 1; $i -lt $parts.Count; $i++) { $parts[$i] })

        $records += [PSCustomObject]@{
            Key    = $parts[0]
            Values = $values
        }
    }
    # Comma-wrapped so a 0- or 1-record file still returns an array (cf.
    # manifest.ps1, which streams instead). Callers must ASSIGN this result
    # before iterating — piping it directly yields one item, not N records.
    return ,$records
}
