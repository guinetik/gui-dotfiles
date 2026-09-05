#Requires -Version 7
# Box-drawing output shared by myenv and tradecraft. These return strings
# instead of writing to the host so they can be asserted on in tests.

$script:Ansi = @{
    bold   = "`e[1m"
    blue   = "`e[34m"
    green  = "`e[32m"
    yellow = "`e[33m"
    red    = "`e[31m"
    reset  = "`e[0m"
}

$script:BoxWidth = 62

function Format-BoxTop {
    param([Parameter(Mandatory)][string]$Title)
    # -5 not -4: the prefix '╭─ ' is 3 chars, the space after the title 1, the
    # closing '╮' 1. Using -4 makes the top border one char wider than the bottom.
    $dashes = '─' * [Math]::Max(1, $script:BoxWidth - $Title.Length - 5)
    "$($script:Ansi.bold)$($script:Ansi.blue)╭─ $Title $dashes╮$($script:Ansi.reset)"
}

function Format-BoxLine {
    param([string]$Text = '')
    "$($script:Ansi.blue)│$($script:Ansi.reset) $Text"
}

function Format-BoxItem {
    param([Parameter(Mandatory)][string]$Text, [string]$Marker = '✓', [string]$Color = 'green')
    $c = $script:Ansi[$Color]
    "$($script:Ansi.blue)│$($script:Ansi.reset)   $c$Marker$($script:Ansi.reset) $Text"
}

function Format-BoxSection {
    param([Parameter(Mandatory)][string]$Title)
    "$($script:Ansi.blue)│$($script:Ansi.reset) $($script:Ansi.bold)${Title}:$($script:Ansi.reset)"
}

function Format-BoxBottom {
    "$($script:Ansi.blue)╰$('─' * ($script:BoxWidth - 2))╯$($script:Ansi.reset)"
}

function Format-Tip {
    param([Parameter(Mandatory)][string]$Text)
    "$($script:Ansi.yellow)   • $Text$($script:Ansi.reset)"
}

function Format-TipHeader {
    param([Parameter(Mandatory)][string]$Text)
    "$($script:Ansi.yellow)$Text$($script:Ansi.reset)"
}
