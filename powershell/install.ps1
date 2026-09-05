#Requires -Version 7
<#
.SYNOPSIS
    Windows installer for gui-dotfiles.
.DESCRIPTION
    Sets $env:DOTFILES, ensures amh2w is installed, hands the package manifest
    to amh2w's bootstrap, and symlinks config files into place.
.PARAMETER WhatIf
    Print the plan and change nothing.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipPackages
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\lib\links.ps1"

Write-Host "gui-dotfiles installer" -ForegroundColor Cyan
Write-Host "Repo root: $RepoRoot"

# 1. Persist DOTFILES for future shells.
if ($PSCmdlet.ShouldProcess('DOTFILES user environment variable', "set to $RepoRoot")) {
    [Environment]::SetEnvironmentVariable('DOTFILES', $RepoRoot, 'User')
    $env:DOTFILES = $RepoRoot
}

# 2. Ensure amh2w. It is not on PSGallery and has no module manifest: the
#    install path is clone the repo and run its install.ps1, which copies
#    core/ and all/ into the first PSModulePath entry.
if (-not (Get-Module -ListAvailable -Name AMH2W)) {
    $amh2wPath = Join-Path (Split-Path -Parent $RepoRoot) 'amh2w'
    if ($PSCmdlet.ShouldProcess($amh2wPath, 'clone and install amh2w')) {
        if (-not (Test-Path -LiteralPath $amh2wPath)) {
            git clone https://github.com/guinetik/amh2w $amh2wPath
        }
        & (Join-Path $amh2wPath 'install.ps1')
    }
} else {
    Write-Host "amh2w already installed" -ForegroundColor Green
}

# 3. Install packages through amh2w's bootstrap, which self-elevates and
#    prompts per package.
if (-not $SkipPackages) {
    $manifest = Join-Path $RepoRoot 'windows\packages.json'
    if ($PSCmdlet.ShouldProcess($manifest, 'bootstrap packages via amh2w')) {
        all my homies bootstrap $manifest
    }
}

# 4. Apply symlinks. Developer Mode is required for unelevated symlinks.
foreach ($link in (Get-LinkPlan -LinksPath (Join-Path $RepoRoot 'windows\links.psv') -RepoRoot $RepoRoot)) {
    Write-Host "  link $($link.Target) -> $($link.Source)"

    # Never clobber a real file. See Test-SafeToLink for why.
    if (-not (Test-SafeToLink -Target $link.Target)) {
        Write-Warning "Refusing to replace $($link.Target): it is a real file, not a symlink. Move or delete it yourself, then re-run."
        continue
    }

    if ($PSCmdlet.ShouldProcess($link.Target, "symlink to $($link.Source)")) {
        $parent = Split-Path -Parent $link.Target
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        New-Item -ItemType SymbolicLink -Path $link.Target -Target $link.Source -Force | Out-Null
    }
}

# 5. Make sure the profile actually loads drop-ins.
$configPath = Join-Path (Split-Path $PROFILE) 'AMH2W-Profile-Config.json'
if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (-not $config.Dropins) {
        if ($PSCmdlet.ShouldProcess($configPath, 'enable Dropins')) {
            $config.Dropins = $true
            $config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configPath -Encoding utf8
        }
    } else {
        Write-Host "Drop-ins already enabled" -ForegroundColor Green
    }
} else {
    Write-Warning "No AMH2W-Profile-Config.json found at $configPath - drop-ins may not load."
}

Write-Host "`nDone. Open a new shell, then run: myenv" -ForegroundColor Green
