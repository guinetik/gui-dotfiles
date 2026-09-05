# Windows Dotfiles Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `myenv` and `tradecraft` work natively in PowerShell 7, turn this repo into the single home for Linux and Windows dotfiles, and delegate Windows provisioning to amh2w.

**Architecture:** Configs stay in tool-named directories because they are identical across platforms — only link targets differ. The two platform-specific concerns (what to install, where files link) move out of shell scripts into data files that each consumer reads natively: JSON for Windows (amh2w mandates it, pwsh parses it natively), pipe-delimited for bash (no `jq` dependency). Pure functions are separated from output so they can be tested without capturing a rendered box.

**Tech Stack:** PowerShell 7.6.5, bash, amh2w (PowerShell DSL), no external test framework.

**Spec:** `docs/superpowers/specs/2026-09-04-windows-dotfiles-unification-design.md`

## Global Constraints

- **PowerShell 7 required.** Installed version is 7.6.5. Scripts start with `#Requires -Version 7`.
- **No new dependencies.** No `jq`, no Pester, no `bats`. This repo bootstraps bare machines; every script must run before anything is installed. Pester on this machine is 3.4.0 (incompatible with modern syntax) and `bats` is absent — hence the hand-rolled assert harnesses in Task 1 and Task 7.
- **Bare function names.** `myenv` and `tradecraft`, not `Get-MyEnvironment`. Matches the bash names and existing muscle memory.
- **amh2w schema is fixed.** `bootstrap.ps1` reads `.name`, `.description`, `.command` off each entry. Additive fields `check` and `checkType` are ignored by it. Never rename or remove the three it reads.
- **`check` is never `convert` on Windows.** `convert` resolves to `C:\WINDOWS\system32\convert.exe`, the NTFS filesystem converter. ImageMagick's probe is `magick`.
- **Symlinks, not copies.** Developer Mode is on (`AllowDevelopmentWithoutDevLicense = 1`), so `New-Item -ItemType SymbolicLink` works unelevated.
- **This repo is public** (`github.com/guinetik/gui-dotfiles`). No key material, no tokens, no `.env` files, ever.
- **Do not commit.** Committing is the repo owner's job. Every task ends with a verification step and a report, never `git add` or `git commit`.
- **Path separators.** PSV files always use `/`. PowerShell consumers convert with `.Replace('/', '\')`.
- **Home expansion.** `windows/links.psv` uses `%USERPROFILE%` (expanded by `[Environment]::ExpandEnvironmentVariables`). `linux/links.psv` uses `$HOME` (expanded by bash parameter substitution). Each is native to its consumer.

---

## File Structure

**Phase 1 — Windows arm (all new, nothing existing breaks)**

| File | Responsibility |
|---|---|
| `test/assert.ps1` | Assert helpers + pass/fail tally + exit code |
| `test/run-all.ps1` | Discovers and runs `test/*.tests.ps1` |
| `powershell/lib/psv.ps1` | Parse pipe-delimited files into records |
| `powershell/lib/render.ps1` | Format box-drawing output lines (returns strings) |
| `powershell/lib/manifest.ps1` | Read `packages.json`, probe whether a tool is installed |
| `powershell/lib/links.ps1` | Turn a `links.psv` into an absolute source/target plan |
| `powershell/functions.ps1` | `myenv` and `tradecraft` |
| `powershell/dotfiles.ps1` | Profile drop-in: sets `$env:DOTFILES`, dot-sources `functions.ps1` |
| `powershell/install.ps1` | Ensure amh2w, bootstrap packages, apply links, enable drop-ins |
| `windows/packages.json` | Dev-machine package manifest (amh2w schema) |
| `windows/links.psv` | Windows link map |
| `tradecraft.psv` | Shared preference text, read by both shells |

**Phase 2 — Linux data extraction (touches working code)**

| File | Responsibility |
|---|---|
| `test/assert.sh` | Bash assert helpers, mirroring `assert.ps1` |
| `test/run-all.sh` | Runs `test/*.tests.sh` |
| `shell/lib/psv.sh` | Strip comments/blanks from a PSV file |
| `linux/packages.psv` | Linux tool catalog |
| `linux/links.psv` | Linux link map, extracted from `create_symlinks.sh:16-25` |
| `shell/functions.sh` | Modified: `myenv`/`tradecraft` render from data. `promptmode` untouched |
| `common/create_symlinks.sh` | Modified: reads `linux/links.psv` |

**Phase 3 — Hygiene and migration**

| File | Responsibility |
|---|---|
| `.gitignore` | New. Aggressive secret patterns |
| `CLAUDE.md`, `.claude/CLAUDE.md`, `README.md` | Modified: kill `tour`, reconcile vocabulary, Windows quick start |
| `windows/terminal/settings.json`, `windows/scripts/*` | Migrated from gui-configs |

---

## Task 1: Test harness

**Files:**
- Create: `test/assert.ps1`
- Create: `test/run-all.ps1`
- Test: `test/harness.tests.ps1`

**Interfaces:**
- Consumes: nothing.
- Produces: `Assert-Equal -Actual <obj> -Expected <obj> -Message <string>`, `Assert-True -Condition <bool> -Message <string>`, `Assert-Throws -ScriptBlock <scriptblock> -Message <string>`, `Test-Case -Name <string> -Body <scriptblock>`, `Get-TestSummary` returning `[PSCustomObject]@{ Passed=<int>; Failed=<int> }`. Every later PowerShell task dot-sources `test/assert.ps1`.

- [ ] **Step 1: Write the failing test**

Create `test/harness.tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/harness.tests.ps1`
Expected: FAIL — `. : The term '...\assert.ps1' is not recognized` (the file does not exist yet).

- [ ] **Step 3: Write the harness**

Create `test/assert.ps1`:

```powershell
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
```

Then append this footer to every `*.tests.ps1` file (including `harness.tests.ps1` now):

```powershell
$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
```

- [ ] **Step 4: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/harness.tests.ps1`
Expected: three `PASS` lines, `3 passed, 0 failed`, exit code 0.

Verify the failure path actually fails — temporarily add `Test-Case 'deliberate' { Assert-Equal -Actual 1 -Expected 2 }`, re-run, confirm one `FAIL` and exit code 1, then delete that case. A harness that cannot fail is not a harness.

- [ ] **Step 5: Write the runner**

Create `test/run-all.ps1`:

```powershell
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
```

- [ ] **Step 6: Verify the runner**

Run: `pwsh -NoProfile -File test/run-all.ps1`
Expected: `=== harness.tests.ps1 ===`, three passes, `All test files passed`, exit code 0.

- [ ] **Step 7: Checkpoint**

Report which files were created and the test output. Do not stage or commit — that is the repo owner's job.

---

## Task 2: PSV parser

**Files:**
- Create: `powershell/lib/psv.ps1`
- Test: `test/psv.tests.ps1`

**Interfaces:**
- Consumes: `test/assert.ps1` from Task 1.
- Produces: `Read-PsvFile -Path <string>` returning an array of `[PSCustomObject]@{ Key=<string>; Values=<string[]> }`. `Key` is the text before the first `|`; `Values` holds everything after, split on `|`. Comment lines (`#`) and blank lines are skipped. A missing file throws. Used by Task 3 (`tradecraft`) and Task 6 (link plan), and mirrored in bash in Task 7.

- [ ] **Step 1: Write the failing test**

Create `test/psv.tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/psv.tests.ps1`
Expected: FAIL — `psv.ps1` does not exist, so dot-sourcing errors before any test runs.

- [ ] **Step 3: Write the implementation**

Create `powershell/lib/psv.ps1`:

```powershell
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
        # NB: `$x = if (...) { @(...) }` unwraps a single-element array to a scalar,
        # and an empty one to $null. Build the array directly instead.
        $values = @(for ($i = 1; $i -lt $parts.Count; $i++) { $parts[$i] })

        $records += [PSCustomObject]@{
            Key    = $parts[0]
            Values = $values
        }
    }
    return ,$records
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/psv.tests.ps1`
Expected: `4 passed, 0 failed`.

- [ ] **Step 5: Checkpoint**

Run `pwsh -NoProfile -File test/run-all.ps1` and confirm both test files pass. Report and stop.

---

## Task 3: tradecraft

**Files:**
- Create: `tradecraft.psv`
- Create: `powershell/lib/render.ps1`
- Create: `powershell/functions.ps1`
- Test: `test/render.tests.ps1`, `test/tradecraft.tests.ps1`

**Interfaces:**
- Consumes: `Read-PsvFile` (Task 2), `test/assert.ps1` (Task 1).
- Produces: `Format-BoxTop -Title <string>`, `Format-BoxLine -Text <string>`, `Format-BoxItem -Text <string> -Marker <string>`, `Format-BoxBottom`, all returning `[string]`; `Get-TradecraftLines -Path <string>` returning `[string[]]`; the `tradecraft` function. Task 5 adds `myenv` to the same `functions.ps1` and reuses every `Format-Box*` helper.

The renderers **return strings rather than writing to the host** so they can be asserted on directly. `tradecraft` and `myenv` are the only things that call `Write-Host`.

- [ ] **Step 1: Write the failing renderer test**

Create `test/render.tests.ps1`:

```powershell
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
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/render.tests.ps1`
Expected: FAIL — `render.ps1` does not exist.

- [ ] **Step 3: Write the renderer**

Create `powershell/lib/render.ps1`:

```powershell
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
```

`$script:Ansi` is only ever touched inside this file. Callers use the `Format-*`
helpers so no consumer depends on the escape-code table.

- [ ] **Step 4: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/render.tests.ps1`
Expected: `5 passed, 0 failed`.

- [ ] **Step 5: Write the tradecraft data file**

Create `tradecraft.psv` at the repo root. Content is the current `shell/functions.sh` text with the WSL-era claims corrected and `tour` removed:

```
# Shared by bash (shell/functions.sh) and PowerShell (powershell/functions.ps1).
# @title starts the box, @section starts a group, - is a bullet, @tip is a footer line.
@title|Tradecraft: Working with guinetik
@section|Primary technical focus
-|Legacy code modernization (COBOL/CICS -> Java microservices)
-|Agent-based systems and RAG architectures
-|Graph algorithms and network analysis (worker-based compute)
-|Systems automation and DSL design (PowerShell, CLI tools)
-|Open-source: libraries and frameworks you actually use in production
-|Interested in computer science education through practical projects
@section|How they work
-|Architecture-first - designs constraints then delegates
-|Leverage-based - systems where each part feeds the next
-|Socratic - asks questions to guide thinking, not to impress
-|Accessible - deliberately colloquial, anti-intellectual gatekeeping
-|Pragmatic - shows value, not theory; efficiency is respect
@section|Your user prefers
-|NOT to commit code - that's their job, not yours
-|To be asked before running builds (npm run build, mvn install, etc.)
-|Efficiency over exploration - run 'myenv' instead of trial-and-error
-|Modern CLI tools used explicitly (eza, rg, fd, not aliased to GNU)
-|Version managers for languages (nvm, pyenv, jabba, rustup)
@section|Your user values
-|Format on save (black, prettier, rustfmt)
-|LSP-based development with proper linting (flake8, eslint, etc.)
-|Conventional commit messages (feat:, fix:, chore:, etc.)
-|Idempotent, modular scripts with error handling
-|Clear, colored output in shell scripts
@section|How your user thinks
-|Honesty over false positivity - be direct
-|Practical efficiency explanations (not theoretical)
-|Minimal fluff, straight to the point
-|Creative solutions and pragmatic thinking
@section|Your user's ecosystem
-|Windows 11 native daily driver - pwsh 7 + Windows Terminal
-|WSL2 'guidev' for Linux-specific work, not general development
-|Full-stack development: Java, Node.js, Python, Rust
-|Primary project: Guinetik backend (D:\Developer\guinetik-backend)
-|Editors: Neovim, IntelliJ, VS Code
-|Docker/containers for infrastructure
@section|Your user's setup
-|Dotfiles repo: D:\Developer\gui-dotfiles (symlinked to home)
-|Windows provisioning via amh2w: all my homies bootstrap
-|Shell: pwsh 7 with Starship prompt; zsh + Atuin + Zoxide under WSL
-|Run 'myenv' to see all installed tools and what is missing
-|Bitwarden Secrets Manager (BWS CLI) for credentials
@tip|Understand constraints before proposing solutions
@tip|Be direct - honesty > flattery
@tip|Respect efficiency - use 'myenv' instead of trial-and-error
@tip|Ask questions first, don't assume context
@tip|Treat them as domain expert who needs velocity
```

- [ ] **Step 6: Write the failing tradecraft test**

Create `test/tradecraft.tests.ps1`:

```powershell
#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\functions.ps1"

$psv = Join-Path $PSScriptRoot '..\tradecraft.psv'

Test-Case 'renders the title into the top border' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition ($lines[0] -match 'Tradecraft: Working with guinetik') -Message 'title rendered'
}

Test-Case 'renders every bullet from the data file' {
    $lines = Get-TradecraftLines -Path $psv
    $bulletCount = (Read-PsvFile -Path $psv | Where-Object { $_.Key -eq '-' }).Count
    $rendered = ($lines | Where-Object { $_ -match '✓' }).Count
    Assert-Equal -Actual $rendered -Expected $bulletCount -Message 'one rendered line per bullet'
}

Test-Case 'never mentions the nonexistent tour command' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition (-not ($lines -match "'tour'")) -Message 'tour is gone'
}

Test-Case 'describes Windows as the daily driver' {
    $lines = Get-TradecraftLines -Path $psv
    Assert-True -Condition (($lines -match 'Windows 11 native').Count -gt 0) -Message 'ecosystem is current'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
```

- [ ] **Step 7: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/tradecraft.tests.ps1`
Expected: FAIL — `functions.ps1` does not exist.

- [ ] **Step 8: Write functions.ps1 with tradecraft**

Create `powershell/functions.ps1`:

```powershell
#Requires -Version 7
# myenv and tradecraft for Windows. Bare names on purpose: they match the
# bash functions in shell/functions.sh and the muscle memory that goes with them.

. "$PSScriptRoot\lib\psv.ps1"
. "$PSScriptRoot\lib\render.ps1"

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
```

- [ ] **Step 9: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/tradecraft.tests.ps1`
Expected: `4 passed, 0 failed`.

- [ ] **Step 10: Look at the actual output**

Run: `pwsh -NoProfile -Command ". ./powershell/functions.ps1; tradecraft"`
Expected: a colored box. Check by eye that borders line up, no `${...}` leaks into the output, and no stray `|` characters appear. Tests confirm content; only your eyes confirm it looks right.

- [ ] **Step 11: Checkpoint**

Run `pwsh -NoProfile -File test/run-all.ps1`. Report the output and a paste of the rendered box.

---

## Task 4: Windows package manifest

**Files:**
- Create: `windows/packages.json`
- Create: `powershell/lib/manifest.ps1`
- Test: `test/manifest.tests.ps1`

**Interfaces:**
- Consumes: `test/assert.ps1` (Task 1).
- Produces: `Get-PackageManifest -Path <string>` returning an array of `[PSCustomObject]@{ Category; Name; Description; Command; Check; CheckType }`; `Test-ToolInstalled -Entry <PSCustomObject>` returning `[bool]`. Task 5's `Get-EnvReport` consumes both.

**Reference — the manifest is consumed by amh2w unmodified.** `all/my/homies/bootstrap.ps1` reads `.name`, `.description`, `.command` per entry and ignores everything else. `check` and `checkType` exist only for `myenv`.

- [ ] **Step 1: Write the failing test**

Create `test/manifest.tests.ps1`:

```powershell
#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\manifest.ps1"

$manifest = Join-Path $PSScriptRoot '..\windows\packages.json'

Test-Case 'flattens categories into entries' {
    $entries = Get-PackageManifest -Path $manifest
    Assert-True -Condition ($entries.Count -gt 10) -Message 'manifest has entries'
    Assert-True -Condition ($null -ne ($entries | Where-Object { $_.Name -eq 'ripgrep' })) -Message 'ripgrep present'
}

Test-Case 'every entry carries the three fields amh2w requires' {
    foreach ($entry in (Get-PackageManifest -Path $manifest)) {
        Assert-True -Condition ([bool]$entry.Name) -Message "name missing on an entry"
        Assert-True -Condition ([bool]$entry.Description) -Message "description missing on $($entry.Name)"
        Assert-True -Condition ([bool]$entry.Command) -Message "command missing on $($entry.Name)"
    }
}

Test-Case 'checkType defaults to command' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'ripgrep' }
    Assert-Equal -Actual $entry.CheckType -Expected 'command' -Message 'default checkType'
}

Test-Case 'ImageMagick probes magick, never convert' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'imagemagick' }
    Assert-Equal -Actual $entry.Check -Expected 'magick' -Message 'imagemagick check'
}

Test-Case 'no entry anywhere probes convert' {
    # C:\WINDOWS\system32\convert.exe is the NTFS filesystem converter and is
    # always present. Probing it reports ImageMagick as installed when it is not.
    $offenders = Get-PackageManifest -Path $manifest | Where-Object { $_.Check -eq 'convert' }
    Assert-Equal -Actual $offenders.Count -Expected 0 -Message 'no convert probes'
}

Test-Case 'entries with no check are provisioning steps' {
    $entry = Get-PackageManifest -Path $manifest | Where-Object { $_.Name -eq 'winget-upgrade' }
    Assert-True -Condition (-not $entry.Check) -Message 'winget-upgrade has no check'
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $false -Message 'no check means not a tool'
}

Test-Case 'detects an installed command' {
    $entry = [PSCustomObject]@{ Check = 'pwsh'; CheckType = 'command' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $true -Message 'pwsh is installed'
}

Test-Case 'detects a missing command' {
    $entry = [PSCustomObject]@{ Check = 'definitely-not-a-real-binary-xyz'; CheckType = 'command' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $false -Message 'missing tool'
}

Test-Case 'detects an installed module' {
    $entry = [PSCustomObject]@{ Check = 'PSReadLine'; CheckType = 'module' }
    Assert-Equal -Actual (Test-ToolInstalled -Entry $entry) -Expected $true -Message 'PSReadLine is installed'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/manifest.tests.ps1`
Expected: FAIL — `manifest.ps1` does not exist.

- [ ] **Step 3: Write the manifest reader**

Create `powershell/lib/manifest.ps1`:

```powershell
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
    return ,$entries
}

function Test-ToolInstalled {
    param([Parameter(Mandatory)][PSCustomObject]$Entry)

    if (-not $Entry.Check) { return $false }

    if ($Entry.CheckType -eq 'module') {
        return [bool](Get-Module -ListAvailable -Name $Entry.Check -ErrorAction SilentlyContinue)
    }
    return [bool](Get-Command $Entry.Check -ErrorAction SilentlyContinue)
}
```

- [ ] **Step 4: Write the manifest data file**

Create `windows/packages.json`. Dev-machine only — no browsers, chat apps, or games; those stay in amh2w's own manifest. Entries for tools that are *not* installed are deliberate: `myenv` doubles as the to-do list, and `bootstrap` is how it gets cleared.

```json
{
  "core": [
    { "name": "winget-upgrade", "description": "Upgrade the winget package manager", "command": "winget upgrade winget" },
    { "name": "git", "description": "Git version control", "command": "winget install --id Git.Git -e --source winget", "check": "git" },
    { "name": "gh", "description": "GitHub CLI", "command": "scoop install gh", "check": "gh" },
    { "name": "scoop-sudo", "description": "sudo for Windows via scoop", "command": "scoop install sudo" },
    { "name": "7zip", "description": "7-Zip archive tool", "command": "choco install 7zip -y", "check": "7z" },
    { "name": "jq", "description": "Command-line JSON processor", "command": "scoop install jq", "check": "jq" }
  ],
  "cli": [
    { "name": "ripgrep", "description": "Blazingly fast grep alternative", "command": "winget install BurntSushi.ripgrep.MSVC", "check": "rg" },
    { "name": "eza", "description": "Enhanced ls - colorful listing with git integration", "command": "scoop install eza", "check": "eza" },
    { "name": "bat", "description": "Syntax-highlighted cat with line numbers", "command": "scoop install bat", "check": "bat" },
    { "name": "fd", "description": "Fast find with simpler syntax", "command": "scoop install fd", "check": "fd" },
    { "name": "dust", "description": "Disk usage analysis - prettier du", "command": "scoop install dust", "check": "dust" },
    { "name": "bottom", "description": "System monitor replacing top", "command": "scoop install bottom", "check": "btm" },
    { "name": "delta", "description": "Syntax-highlighted git diffs", "command": "scoop install delta", "check": "delta" },
    { "name": "fzf", "description": "Fuzzy finder for files and commands", "command": "scoop install fzf", "check": "fzf" },
    { "name": "tealdeer", "description": "Quick command documentation (tldr)", "command": "scoop install tealdeer", "check": "tldr" }
  ],
  "shell": [
    { "name": "starship", "description": "Fast, customizable prompt", "command": "winget install Starship.Starship", "check": "starship" },
    { "name": "zoxide", "description": "Smart directory jumping (z command)", "command": "winget install ajeetdsouza.zoxide", "check": "zoxide" },
    { "name": "atuin", "description": "Enhanced shell history with search and sync", "command": "scoop install atuin", "check": "atuin" },
    { "name": "windows-terminal", "description": "Windows Terminal", "command": "winget install Microsoft.WindowsTerminal", "check": "wt" },
    { "name": "pwsh", "description": "PowerShell 7", "command": "winget install Microsoft.PowerShell", "check": "pwsh" }
  ],
  "editors": [
    { "name": "neovim", "description": "Neovim - modern vim with Lua configuration", "command": "scoop install neovim", "check": "nvim" },
    { "name": "vscode", "description": "Visual Studio Code", "command": "winget install Microsoft.VisualStudioCode", "check": "code" },
    { "name": "micro", "description": "Nano-like editor with modern features", "command": "scoop install micro", "check": "micro" }
  ],
  "runtimes": [
    { "name": "nvm", "description": "Node.js via nvm for Windows", "command": "winget install CoreyButler.NVMforWindows", "check": "node" },
    { "name": "bun", "description": "Bun JavaScript runtime and package manager", "command": "scoop install bun", "check": "bun" },
    { "name": "pnpm", "description": "Fast, disk-efficient package manager", "command": "npm install -g pnpm", "check": "pnpm" },
    { "name": "pyenv-win", "description": "Python version manager for Windows", "command": "scoop install pyenv", "check": "python" },
    { "name": "uv", "description": "Fast Python package installer and resolver", "command": "winget install astral-sh.uv", "check": "uv" },
    { "name": "rustup", "description": "Rust toolchain installer", "command": "winget install Rustlang.Rustup", "check": "cargo" },
    { "name": "dotnet", "description": ".NET SDK", "command": "winget install Microsoft.DotNet.SDK.8", "check": "dotnet" },
    { "name": "jabba", "description": "Java version manager", "command": "scoop install jabba", "check": "jabba" },
    { "name": "maven", "description": "Java build tool", "command": "scoop install maven", "check": "mvn" },
    { "name": "go", "description": "Go toolchain", "command": "winget install GoLang.Go", "check": "go" }
  ],
  "containers": [
    { "name": "docker-desktop", "description": "Docker container runtime", "command": "winget install Docker.DockerDesktop", "check": "docker" },
    { "name": "ollama", "description": "Local LLM inference engine", "command": "winget install Ollama.Ollama", "check": "ollama" }
  ],
  "media": [
    { "name": "ffmpeg", "description": "Video/audio processing and conversion", "command": "choco install ffmpeg -y", "check": "ffmpeg" },
    { "name": "imagemagick", "description": "Image manipulation toolkit", "command": "scoop install main/imagemagick", "check": "magick" }
  ],
  "security": [
    { "name": "bws", "description": "Bitwarden Secrets Manager CLI", "command": "choco install bitwarden-secrets-manager-cli -y", "check": "bws" }
  ],
  "node-globals": [
    { "name": "claude-code", "description": "Claude Code CLI", "command": "npm install -g @anthropic-ai/claude-code", "check": "claude" },
    { "name": "branchlet", "description": "Git worktree manager", "command": "npm install -g branchlet", "check": "branchlet" },
    { "name": "typescript", "description": "TypeScript compiler", "command": "npm install -g typescript", "check": "tsc" }
  ],
  "powershell-modules": [
    { "name": "PSReadLine", "description": "Command-line editing and prediction", "command": "Install-Module PSReadLine -Scope CurrentUser -Force", "check": "PSReadLine", "checkType": "module" },
    { "name": "Terminal-Icons", "description": "File type icons in directory listings", "command": "Install-Module Terminal-Icons -Scope CurrentUser -Force", "check": "Terminal-Icons", "checkType": "module" },
    { "name": "AMH2W", "description": "All My Homies Handle Windows - provisioning DSL", "command": "git clone https://github.com/guinetik/amh2w && ./amh2w/install.ps1", "check": "AMH2W", "checkType": "module" }
  ]
}
```

- [ ] **Step 5: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/manifest.tests.ps1`
Expected: `9 passed, 0 failed`.

- [ ] **Step 6: Verify the JSON is valid for amh2w too**

Run: `pwsh -NoProfile -Command "(Get-Content windows/packages.json -Raw | ConvertFrom-Json).PSObject.Properties.Name"`
Expected: the ten category names (`core`, `cli`, `shell`, `editors`, `runtimes`, `containers`, `media`, `security`, `node-globals`, `powershell-modules`), no parse error. This is the exact call `bootstrap.ps1:31` makes.

- [ ] **Step 7: Checkpoint**

Run `pwsh -NoProfile -File test/run-all.ps1`. Report.

---

## Task 5: myenv

**Files:**
- Modify: `powershell/functions.ps1` (append; Task 3 created it)
- Test: `test/myenv.tests.ps1`

**Interfaces:**
- Consumes: `Get-PackageManifest`, `Test-ToolInstalled` (Task 4); `Format-Box*` (Task 3); `Get-DotfilesRoot` (Task 3).
- Produces: `Get-EnvReport -ManifestPath <string>` returning `[PSCustomObject]@{ Category; Name; Description; Installed }` per tool entry; `Get-MyEnvLines -ManifestPath <string>` returning `[string[]]`; the `myenv` function.

- [ ] **Step 1: Write the failing test**

Create `test/myenv.tests.ps1`:

```powershell
#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\functions.ps1"

$manifest = Join-Path $PSScriptRoot '..\windows\packages.json'

Test-Case 'report excludes provisioning steps that have no check' {
    $report = Get-EnvReport -ManifestPath $manifest
    $offenders = $report | Where-Object { $_.Name -eq 'winget-upgrade' }
    Assert-Equal -Actual $offenders.Count -Expected 0 -Message 'winget-upgrade excluded'
}

Test-Case 'report marks an installed tool as installed' {
    $report = Get-EnvReport -ManifestPath $manifest
    $entry = $report | Where-Object { $_.Name -eq 'pwsh' }
    Assert-Equal -Actual $entry.Installed -Expected $true -Message 'pwsh detected'
}

Test-Case 'report preserves categories' {
    $report = Get-EnvReport -ManifestPath $manifest
    Assert-True -Condition (($report | Where-Object { $_.Category -eq 'cli' }).Count -gt 0) -Message 'cli category present'
}

Test-Case 'ImageMagick is not falsely reported via convert' {
    # Regression: C:\WINDOWS\system32\convert.exe always exists.
    $report = Get-EnvReport -ManifestPath $manifest
    $entry = $report | Where-Object { $_.Name -eq 'imagemagick' }
    $magickReal = [bool](Get-Command magick -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $entry.Installed -Expected $magickReal -Message 'tracks magick, not convert'
}

Test-Case 'rendered output has a line per reported tool' {
    $report = Get-EnvReport -ManifestPath $manifest
    $lines = Get-MyEnvLines -ManifestPath $manifest
    $marked = ($lines | Where-Object { $_ -match '✓' -or $_ -match '✗' }).Count
    Assert-Equal -Actual $marked -Expected $report.Count -Message 'one marked line per tool'
}

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/myenv.tests.ps1`
Expected: FAIL — `Get-EnvReport` is not recognized.

- [ ] **Step 3: Implement**

Append to `powershell/functions.ps1`, and add `. "$PSScriptRoot\lib\manifest.ps1"` next to the existing dot-source lines at the top of the file:

```powershell
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
```

- [ ] **Step 4: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/myenv.tests.ps1`
Expected: `5 passed, 0 failed`.

- [ ] **Step 5: Check the output against reality**

Run: `pwsh -NoProfile -Command ". ./powershell/functions.ps1; myenv"`

Compare against the audit recorded in the spec. Expected green: rg, zoxide, starship, nvim, node, bun, python, uv, cargo, docker, ffmpeg, magick, git, gh, jq, 7z, bws, pnpm, dotnet, mvn, code, wt, pwsh, claude, branchlet, tsc, PSReadLine, Terminal-Icons, AMH2W. Expected red: eza, bat, fd, dust, btm, delta, fzf, tldr, atuin, micro, jabba, go, ollama.

**The specific thing to verify: `imagemagick` shows green** (because `magick` really is installed at `D:\scoop\apps\imagemagick\current\magick.exe`) **and no entry shows green merely because `convert.exe` exists.**

- [ ] **Step 6: Checkpoint**

Run `pwsh -NoProfile -File test/run-all.ps1`. Report the full `myenv` output.

---

## Task 6: Drop-in, link map, and installer

**Files:**
- Create: `powershell/lib/links.ps1`
- Create: `powershell/dotfiles.ps1`
- Create: `windows/links.psv`
- Create: `powershell/install.ps1`
- Test: `test/links.tests.ps1`

**Interfaces:**
- Consumes: `Read-PsvFile` (Task 2).
- Produces: `Get-LinkPlan -LinksPath <string> -RepoRoot <string>` returning `[PSCustomObject]@{ Source; Target }` per link, with `Source` absolute and backslash-separated, `Target` fully environment-expanded.

- [ ] **Step 1: Write the failing test**

Create `test/links.tests.ps1`:

```powershell
#Requires -Version 7
. "$PSScriptRoot\assert.ps1"
. "$PSScriptRoot\..\powershell\lib\links.ps1"

$fixture = Join-Path ([System.IO.Path]::GetTempPath()) "links-test-$PID.psv"
@'
# comment
powershell/dotfiles.ps1|%USERPROFILE%/Documents/PowerShell/drop-ins/00-gui-dotfiles.ps1
'@ | Set-Content -LiteralPath $fixture -Encoding utf8

Test-Case 'source becomes an absolute repo path with backslashes' {
    $plan = Get-LinkPlan -LinksPath $fixture -RepoRoot 'D:\Developer\gui-dotfiles'
    Assert-Equal -Actual $plan[0].Source -Expected 'D:\Developer\gui-dotfiles\powershell\dotfiles.ps1' -Message 'source path'
}

Test-Case 'target expands environment variables' {
    $plan = Get-LinkPlan -LinksPath $fixture -RepoRoot 'D:\Developer\gui-dotfiles'
    Assert-True -Condition (-not ($plan[0].Target -match '%USERPROFILE%')) -Message 'no unexpanded variable'
    Assert-True -Condition ($plan[0].Target -match 'drop-ins') -Message 'target path preserved'
}

Test-Case 'real links file parses and points every source at a file that exists' {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
    $plan = Get-LinkPlan -LinksPath (Join-Path $repoRoot 'windows\links.psv') -RepoRoot $repoRoot
    Assert-True -Condition ($plan.Count -gt 0) -Message 'plan is not empty'
    foreach ($link in $plan) {
        Assert-True -Condition (Test-Path -LiteralPath $link.Source) -Message "source missing: $($link.Source)"
    }
}

Remove-Item -LiteralPath $fixture -Force

$summary = Get-TestSummary
Write-Host "$($summary.Passed) passed, $($summary.Failed) failed"
if ($summary.Failed -gt 0) { exit 1 }
```

- [ ] **Step 2: Run it to verify it fails**

Run: `pwsh -NoProfile -File test/links.tests.ps1`
Expected: FAIL — `links.ps1` does not exist.

- [ ] **Step 3: Write the link planner**

Create `powershell/lib/links.ps1`:

```powershell
#Requires -Version 7
. "$PSScriptRoot\psv.ps1"

function Get-LinkPlan {
    param(
        [Parameter(Mandatory)][string]$LinksPath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    # Assign before iterating. Read-PsvFile ends with `return ,$records`, so
    # piping it emits the inner array as ONE pipeline item, not N records.
    $records = Read-PsvFile -Path $LinksPath
    foreach ($record in $records) {
        [PSCustomObject]@{
            Source = Join-Path $RepoRoot ($record.Key -replace '/', '\')
            Target = [Environment]::ExpandEnvironmentVariables($record.Values[0]) -replace '/', '\'
        }
    }
}
```

- [ ] **Step 4: Write the drop-in and the link map**

Create `powershell/dotfiles.ps1`:

```powershell
#Requires -Version 7
# Profile drop-in. Symlinked into Documents\PowerShell\drop-ins\ so the repo
# stays the source of truth: edits here take effect in the next shell.

$env:DOTFILES = 'D:\Developer\gui-dotfiles'
if (Test-Path -LiteralPath "$env:DOTFILES\powershell\functions.ps1") {
    . "$env:DOTFILES\powershell\functions.ps1"
}
```

Create `windows/links.psv`:

```
# source (repo-relative, forward slashes) | target (%VAR% expanded by PowerShell)
# Prefixed 00- because the profile dot-sources drop-ins alphabetically.
powershell/dotfiles.ps1|%USERPROFILE%/Documents/PowerShell/drop-ins/00-gui-dotfiles.ps1
#
# Deliberately NOT linked here: .claude/CLAUDE.md -> %USERPROFILE%\.claude\CLAUDE.md.
# The Linux map does link it, because under WSL the repo's project-context file
# IS the user's global instruction file. On Windows they are two different
# documents: %USERPROFILE%\.claude\CLAUDE.md holds personal global instructions
# that the repo's project-context file would destroy. Do not add this line.
```

- [ ] **Step 5: Run it to verify it passes**

Run: `pwsh -NoProfile -File test/links.tests.ps1`
Expected: `3 passed, 0 failed`.

- [ ] **Step 6: Write the installer**

Create `powershell/install.ps1`:

```powershell
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

    # Never clobber a real file. `New-Item -Force` deletes whatever sits at the
    # target, symlink or not — that is how an earlier version of this installer
    # destroyed the user's ~/.claude/CLAUDE.md. Replacing our own symlink is
    # fine; replacing a file someone actually wrote is not ours to do.
    $existing = Get-Item -LiteralPath $link.Target -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -ne 'SymbolicLink') {
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
```

- [ ] **Step 7: Verify the dry run changes nothing**

Run: `pwsh -NoProfile -File powershell/install.ps1 -WhatIf`
Expected: prints the `DOTFILES` set, the amh2w check, the bootstrap call, and one `link` line per entry in `windows/links.psv`. Nothing is created.

Confirm it really changed nothing:
`pwsh -NoProfile -Command "Test-Path $HOME\Documents\PowerShell\drop-ins\00-gui-dotfiles.ps1"`
Expected: `False`.

- [ ] **Step 8: Run it for real, without packages**

Run: `pwsh -NoProfile -File powershell/install.ps1 -SkipPackages`

`-SkipPackages` is deliberate here: package installation is a separate, slower, interactive concern and this step is verifying the *wiring*. Then open a **new** pwsh window and run `myenv` and `tradecraft` with no dot-sourcing. Both must work from the drop-in alone.

- [ ] **Step 9: Checkpoint**

Run `pwsh -NoProfile -File test/run-all.ps1`. Report the test output, plus confirmation that `myenv` works in a fresh shell. **Phase 1 is complete here** — everything so far was additive, and nothing existing has been touched.

---

## Task 7: Bash test harness and PSV reader

**Files:**
- Create: `test/assert.sh`
- Create: `test/run-all.sh`
- Create: `shell/lib/psv.sh`
- Test: `test/psv.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `assert_equal <actual> <expected> <message>`, `assert_true <status> <message>`, `test_case <name>`, `test_summary` (exits 1 on failure); `psv_filter <path>` printing the file's real records with comments and blank lines removed.

**Note:** Phase 2 modifies working code. Every task from here compares new output against current output before replacing anything.

- [ ] **Step 1: Capture current behavior first**

Before writing anything, record what the existing functions produce, to diff against later:

```bash
bash -c 'source shell/functions.sh; tradecraft' > /tmp/tradecraft-before.txt 2>&1
bash -c 'source shell/functions.sh; myenv' > /tmp/myenv-before.txt 2>&1
wc -l /tmp/tradecraft-before.txt /tmp/myenv-before.txt
```

Expected: both files non-empty. These are the baseline for Task 8 and Task 9.

- [ ] **Step 2: Write the failing test**

Create `test/psv.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"

fixture="$(mktemp)"
cat > "$fixture" <<'EOF'
# a comment
@section|Modern CLI Tools

eza|Enhanced ls
EOF

test_case "strips comments and blank lines"
count=$(psv_filter "$fixture" | wc -l)
assert_equal "$count" "2" "two real records"

test_case "preserves field content"
first=$(psv_filter "$fixture" | head -1)
assert_equal "$first" "@section|Modern CLI Tools" "first record intact"

rm -f "$fixture"
test_summary
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash test/psv.tests.sh`
Expected: FAIL — `assert.sh: No such file or directory`.

- [ ] **Step 4: Write the harness and the reader**

Create `test/assert.sh`:

```bash
#!/usr/bin/env bash
# Minimal assert harness, mirroring test/assert.ps1. No dependencies on
# purpose: this repo bootstraps bare machines.

PASSED=0
FAILED=0
CURRENT_CASE=""

test_case() { CURRENT_CASE="$1"; }

assert_equal() {
  local actual="$1" expected="$2" message="$3"
  if [ "$actual" = "$expected" ]; then
    PASSED=$((PASSED + 1))
    printf '  PASS  %s: %s\n' "$CURRENT_CASE" "$message"
  else
    FAILED=$((FAILED + 1))
    printf '  FAIL  %s: %s\n        expected: <%s>\n        actual:   <%s>\n' \
      "$CURRENT_CASE" "$message" "$expected" "$actual"
  fi
}

assert_true() {
  local status="$1" message="$2"
  if [ "$status" -eq 0 ]; then
    PASSED=$((PASSED + 1))
    printf '  PASS  %s: %s\n' "$CURRENT_CASE" "$message"
  else
    FAILED=$((FAILED + 1))
    printf '  FAIL  %s: %s\n' "$CURRENT_CASE" "$message"
  fi
}

test_summary() {
  printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
  [ "$FAILED" -eq 0 ] || exit 1
}
```

Create `shell/lib/psv.sh`:

```bash
#!/usr/bin/env bash
# Pipe-delimited record reading for bash. Mirrors powershell/lib/psv.ps1.
# Callers parse fields with: IFS='|' read -r key rest

psv_filter() {
  local path="$1"
  [ -f "$path" ] || { echo "PSV file not found: $path" >&2; return 1; }
  grep -v '^[[:space:]]*#' "$path" | grep -v '^[[:space:]]*$'
}
```

Create `test/run-all.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
for file in "$SCRIPT_DIR"/*.tests.sh; do
  printf '\n=== %s ===\n' "$(basename "$file")"
  output=$(bash "$file" 2>&1)
  status=$?
  printf '%s\n' "$output"
  # A file that prints FAIL but exits 0 forgot to call test_summary (which is
  # what sets the exit code). Do not let that read as success — a silently
  # green suite is worse than a red one.
  if [ "$status" -ne 0 ] || printf '%s' "$output" | grep -q '^ *FAIL'; then
    failed=$((failed + 1))
    if [ "$status" -eq 0 ]; then
      printf '  (this file printed FAIL but exited 0 — missing test_summary?)\n'
    fi
  fi
done
if [ "$failed" -gt 0 ]; then
  printf '\n%d test file(s) failed\n' "$failed"
  exit 1
fi
printf '\nAll test files passed\n'
```

- [ ] **Step 5: Run it to verify it passes**

Run: `bash test/psv.tests.sh`
Expected: `2 passed, 0 failed`.

Then verify the harness can fail: temporarily add `assert_equal "1" "2" "deliberate"`, re-run, confirm a FAIL line and exit code 1, then remove it.

- [ ] **Step 6: Checkpoint**

Run `bash test/run-all.sh`. Report.

---

## Task 8: bash tradecraft reads the shared data file

**Files:**
- Modify: `shell/functions.sh` (the `tradecraft` function, currently lines 201-295)
- Test: `test/tradecraft.tests.sh`

**Interfaces:**
- Consumes: `psv_filter` (Task 7), `tradecraft.psv` (Task 3).
- Produces: a `tradecraft` bash function rendering the same data the PowerShell one does.

- [ ] **Step 1: Write the failing test**

Create `test/tradecraft.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
export DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/shell/functions.sh"

output=$(tradecraft)

test_case "renders the title"
echo "$output" | grep -q "Tradecraft: Working with guinetik"
assert_true $? "title present"

test_case "renders one bullet line per data bullet"
expected=$(grep -c '^-|' "$DOTFILES/tradecraft.psv")
actual=$(echo "$output" | grep -c '✓')
assert_equal "$actual" "$expected" "bullet count matches data file"

test_case "no longer mentions the nonexistent tour command"
echo "$output" | grep -q "'tour'"
[ $? -ne 0 ]
assert_true $? "tour is gone"

test_case "describes Windows as the daily driver"
echo "$output" | grep -q "Windows 11 native"
assert_true $? "ecosystem is current"

test_summary
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash test/tradecraft.tests.sh`
Expected: FAIL on the title/bullet/tour cases — the current `tradecraft` has hardcoded text, still says `'tour'`, and still claims WSL2 Ubuntu.

- [ ] **Step 3: Replace the tradecraft function**

In `shell/functions.sh`, replace the whole `tradecraft() { ... }` body (currently lines 201-295) with:

```bash
# tradecraft - Display guinetik's working preferences and style
# Content lives in tradecraft.psv at the repo root, shared with PowerShell.
tradecraft() {
  local bold='\033[1m' blue='\033[34m' green='\033[32m' yellow='\033[33m' reset='\033[0m'
  local root="${DOTFILES:-$HOME/.config/gui-dotfiles}"
  local psv="$root/tradecraft.psv"

  if [ ! -f "$psv" ]; then
    echo "tradecraft: data file not found: $psv" >&2
    return 1
  fi

  source "$root/shell/lib/psv.sh"

  local tips=()
  echo ""
  while IFS='|' read -r key value; do
    case "$key" in
      '@title')
        echo -e "${bold}${blue}╭─ ${value} ──────────────────────────────╮${reset}"
        echo -e "${blue}│${reset}"
        ;;
      '@section')
        echo -e "${blue}│${reset} ${bold}${value}:${reset}"
        echo -e "${blue}│${reset}"
        ;;
      '-')
        echo -e "${blue}│${reset}   ${green}✓${reset} ${value}"
        ;;
      '@tip')
        tips+=("$value")
        ;;
    esac
  done < <(psv_filter "$psv")

  echo -e "${blue}│${reset}"
  echo -e "${blue}╰──────────────────────────────────────────────────────────╯${reset}"

  if [ ${#tips[@]} -gt 0 ]; then
    echo ""
    echo -e "${yellow}💡 Work effectively by:${reset}"
    for tip in "${tips[@]}"; do
      echo -e "${yellow}   • ${tip}${reset}"
    done
  fi
  echo ""
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `bash test/tradecraft.tests.sh`
Expected: `4 passed, 0 failed`.

- [ ] **Step 5: Verify both shells agree**

Both renderers read the same file, so their content must match. Compare with ANSI codes stripped:

```bash
bash -c 'export DOTFILES=$(pwd); source shell/functions.sh; tradecraft' \
  | sed 's/\x1b\[[0-9;]*m//g' | grep -o '✓.*' | sort > /tmp/tc-bash.txt
# The OutputEncoding line is required: without it pwsh emits the ✓ glyph as
# mojibake across the Git Bash pipe, and the diff fails for encoding reasons
# rather than content ones.
pwsh -NoProfile -Command '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; . ./powershell/functions.ps1; tradecraft' \
  | sed 's/\x1b\[[0-9;]*m//g' | grep -o '✓.*' | sort > /tmp/tc-pwsh.txt
diff /tmp/tc-bash.txt /tmp/tc-pwsh.txt && echo "RENDERERS AGREE"
```

Expected: `RENDERERS AGREE`. This is the test that makes the drift structural rather than a promise.

- [ ] **Step 6: Checkpoint**

Run `bash test/run-all.sh` and `pwsh -NoProfile -File test/run-all.ps1`. Report both, plus the diff result.

---

## Task 9: bash myenv reads a data file

**Files:**
- Create: `linux/packages.psv`
- Modify: `shell/functions.sh` (the `myenv` function, currently lines 6-196)
- Test: `test/myenv.tests.sh`

**Interfaces:**
- Consumes: `psv_filter` (Task 7).
- Produces: a `myenv` bash function rendering `linux/packages.psv`.

- [ ] **Step 1: Write the data file**

Create `linux/packages.psv`, carrying over the exact tool names and descriptions currently hardcoded in `shell/functions.sh:26-36, 55-60, 77-83, 99-106, 123-128, 145-149, 168-173`:

```
# Linux/WSL tool catalog. Rendered by myenv in shell/functions.sh.
# Format: command|description   (@section starts a group)
@section|Modern CLI Tools (Replacements for GNU tools)
eza|Enhanced ls - colorful file listing with git integration
bat|Syntax-highlighted cat with line numbers and themes
rg|Ripgrep - blazingly fast grep alternative
fd|Fast find command with simpler syntax
dust|Disk usage analysis - prettier du alternative
btm|Bottom - system monitor replacing top
delta|Syntax-highlighted git diffs
procs|Modern process viewer replacing ps
bandwhich|Network bandwidth monitor
tldr|Quick command documentation lookup
@section|Shell Enhancements
zoxide|Smart directory jumping (z command)
atuin|Enhanced shell history with search and sync (Ctrl+R)
starship|Fast, customizable prompt
antidote|Zsh plugin manager
@section|Editors & Development
nvim|Neovim - modern vim with Lua configuration
lvim|LunarVim - Neovim-based IDE-like editor
micro|Nano-like editor with modern features
fzf|Fuzzy finder - for file/command searching
qmd|QMD - local markdown search engine for knowledge management
@section|Language Runtimes
node|Node.js (JavaScript/TypeScript runtime)
bun|Bun (JavaScript/TypeScript runtime & package manager)
python|Python
cargo|Rust toolchain
java|Java (via Jabba)
go|Go (Golang)
@section|System & Containers
docker|Docker container runtime
ollama|Local LLM inference engine for embeddings and inference
oxker|Docker TUI - interactive container manager
nu|Structured shell language (nushell)
@section|Multimedia & Documents
ffmpeg|Video/audio processing and conversion
convert|ImageMagick - image manipulation toolkit
pdflatex|LaTeX - document preparation system
@section|Node.js Global Packages
branchlet|Git worktree manager
claude|Claude Code CLI
tsc|TypeScript compiler
nodemon|Auto-restart Node apps
```

Note `convert` is correct **here** — on Linux it really is ImageMagick. The collision is Windows-only.

- [ ] **Step 2: Write the failing test**

Create `test/myenv.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
export DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES/shell/functions.sh"

output=$(myenv)

test_case "renders one marked line per catalog entry"
expected=$(grep -vc '^@section\|^#\|^$' "$DOTFILES/linux/packages.psv")
actual=$(echo "$output" | grep -c '✓\|✗')
assert_equal "$actual" "$expected" "line count matches catalog"

test_case "renders every section heading"
missing=0
while IFS='|' read -r key value; do
  echo "$output" | grep -qF "$value" || { echo "    missing section: $value"; missing=$((missing + 1)); }
done < <(grep '^@section|' "$DOTFILES/linux/packages.psv")
assert_equal "$missing" "0" "all sections rendered"

test_case "detects a tool that is definitely installed"
echo "$output" | grep -q "✓.*bash\|✓.*rg\|✓.*node"
assert_true $? "at least one known tool detected"

test_summary
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash test/myenv.tests.sh`
Expected: FAIL — the current hardcoded `myenv` renders extra headers and tip lines, so the counts will not match.

- [ ] **Step 4: Replace the myenv function**

In `shell/functions.sh`, replace the whole `myenv() { ... }` body (currently lines 6-196) with:

```bash
# myenv - Display installed tools and environment setup
# Catalog lives in linux/packages.psv; detection happens at runtime.
myenv() {
  local bold='\033[1m' blue='\033[34m' green='\033[32m' yellow='\033[33m' red='\033[31m' reset='\033[0m'
  local root="${DOTFILES:-$HOME/.config/gui-dotfiles}"
  local psv="$root/linux/packages.psv"

  if [ ! -f "$psv" ]; then
    echo "myenv: catalog not found: $psv" >&2
    return 1
  fi

  source "$root/shell/lib/psv.sh"

  local missing=0
  echo ""
  echo -e "${bold}${blue}╭─ My Environment (myenv) ─────────────────────╮${reset}"
  echo -e "${blue}│${reset}"

  while IFS='|' read -r key value; do
    if [ "$key" = "@section" ]; then
      echo -e "${blue}│${reset} ${bold}${value}:${reset}"
      echo -e "${blue}│${reset}"
    else
      if command -v "$key" &>/dev/null; then
        echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${key}${reset} - ${value}"
      else
        echo -e "${blue}│${reset}   ${red}✗${reset} ${key} - ${value}"
        missing=$((missing + 1))
      fi
    fi
  done < <(psv_filter "$psv")

  echo -e "${blue}│${reset}"
  echo -e "${blue}╰────────────────────────────────────────────────╯${reset}"
  echo ""
  echo -e "${yellow}Tip: Modern tools are installed but NOT aliased to GNU commands.${reset}"
  echo -e "${yellow}Use them directly by name (e.g., 'eza', 'rg', 'fd') when you want modern features.${reset}"
  if [ "$missing" -gt 0 ]; then
    echo -e "${yellow}${missing} tool(s) missing. Run ./install.sh to install them.${reset}"
  fi
  echo ""
}
```

- [ ] **Step 5: Run it to verify it passes**

Run: `bash test/myenv.tests.sh`
Expected: `3 passed, 0 failed`.

- [ ] **Step 6: Diff against the captured baseline**

```bash
bash -c 'export DOTFILES=$(pwd); source shell/functions.sh; myenv' \
  | sed 's/\x1b\[[0-9;]*m//g' | grep -o '[✓✗].*' | sort > /tmp/myenv-after.txt
sed 's/\x1b\[[0-9;]*m//g' /tmp/myenv-before.txt | grep -o '[✓✗].*' | sort > /tmp/myenv-base.txt
diff /tmp/myenv-base.txt /tmp/myenv-after.txt && echo "NO BEHAVIOR CHANGE"
```

Expected: `NO BEHAVIOR CHANGE`. The rewrite moved data out of code; it must not change which tools are reported or how they are described. Any diff here is a transcription error in `linux/packages.psv` — fix the data file, not the test.

- [ ] **Step 7: Checkpoint**

Run `bash test/run-all.sh`. Report, including the diff result.

---

## Task 10: create_symlinks.sh reads the link map

**Files:**
- Create: `linux/links.psv`
- Modify: `common/create_symlinks.sh:16-25` (the inline `SYMLINKS` array) and lines 51-52 (the `tour` references)
- Test: `test/links.tests.sh`

**Interfaces:**
- Consumes: `psv_filter` (Task 7).
- Produces: `linux/links.psv` carrying the same pairs currently hardcoded in the `SYMLINKS` array.

- [ ] **Step 1: Write the data file**

Create `linux/links.psv`, transcribed exactly from `common/create_symlinks.sh:16-25`, plus the two new data files:

```
# source (repo-relative) | target ($HOME expanded by bash)
bash/.bashrc|$HOME/.bashrc
zsh/.zshrc|$HOME/.zshrc
zsh/.zshenv|$HOME/.zshenv
zsh/.zsh_plugins.txt|$HOME/.zsh_plugins.txt
shell/aliases.sh|$HOME/.config/shell/aliases.sh
shell/functions.sh|$HOME/.config/shell/functions.sh
starship/starship.toml|$HOME/.config/starship.toml
git/.gitconfig|$HOME/.gitconfig
.claude/CLAUDE.md|$HOME/.claude/CLAUDE.md
```

- [ ] **Step 2: Write the failing test**

Create `test/links.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
source "$SCRIPT_DIR/../shell/lib/psv.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "every link source exists in the repo"
missing=0
while IFS='|' read -r src target; do
  [ -f "$ROOT/$src" ] || { echo "    missing source: $src"; missing=$((missing + 1)); }
done < <(psv_filter "$ROOT/linux/links.psv")
assert_equal "$missing" "0" "no missing sources"

test_case "link map covers the same count as the old hardcoded array"
count=$(psv_filter "$ROOT/linux/links.psv" | wc -l)
assert_equal "$count" "9" "nine links"

test_case "create_symlinks.sh no longer hardcodes a SYMLINKS array"
grep -q 'SYMLINKS=(' "$ROOT/common/create_symlinks.sh"
[ $? -ne 0 ]
assert_true $? "array is gone"

test_summary
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bash test/links.tests.sh`
Expected: the third case FAILS — the array is still there.

- [ ] **Step 4: Rewrite create_symlinks.sh**

In `common/create_symlinks.sh`, replace lines 16-25 (the `SYMLINKS=(...)` array) and the loop's `IFS=':' read` with a read from the data file, and fix the trailing `tour` message. The loop body that creates links is unchanged:

```bash
LINKS_FILE="$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/linux/links.psv"
source "$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/shell/lib/psv.sh"

if [ ! -f "$LINKS_FILE" ]; then
  print_error "Link map not found: $LINKS_FILE"
  return 1 2>/dev/null || exit 1
fi

while IFS='|' read -r source target; do
  # Expand $HOME in the target without eval.
  target="${target/\$HOME/$HOME}"
  source_path="$(cd "$SYMLINKS_SCRIPT_DIR/.." && pwd)/$source"

  if [ -f "$source_path" ]; then
    print_info "Linking $source_path to $target"
    mkdir -p "$(dirname "$target")"
    if ln -sf "$source_path" "$target"; then
      print_success "Created symlink: $target -> $source_path"
    else
      print_error "Failed to create symlink: $target"
    fi
  else
    print_warning "Source file not found: $source_path"
  fi
done < <(psv_filter "$LINKS_FILE")
```

Leave the closing `print_info` messages at lines 51-52 alone — they already name `myenv` and `tradecraft`, which are real commands. The `tour` references live in `shell/functions.sh` (removed in Task 8) and `CLAUDE.md` (Task 11).

- [ ] **Step 5: Run it to verify it passes**

Run: `bash test/links.tests.sh`
Expected: `3 passed, 0 failed`.

- [ ] **Step 6: Verify the links it would create**

The script creates real symlinks in `$HOME`, so dry-run it by pointing `HOME` at a scratch directory:

```bash
scratch=$(mktemp -d)
HOME="$scratch" bash -c 'source common/utils.sh; source common/create_symlinks.sh'
find "$scratch" -type l | sort
```

Expected: nine symlinks, matching `linux/links.psv`. Confirm each resolves into the repo, then `rm -rf "$scratch"`.

- [ ] **Step 7: Checkpoint**

Run `bash test/run-all.sh` and `pwsh -NoProfile -File test/run-all.ps1`. Report both. **Phase 2 is complete here.**

---

## Task 11: gitignore and documentation

**Files:**
- Create: `.gitignore`
- Modify: `CLAUDE.md` (lines 6, 19, 39), `.claude/CLAUDE.md`, `README.md`
- Test: `test/docs.tests.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: no code. This task's deliverable is that `tour` no longer appears and secrets cannot be committed.

- [ ] **Step 1: Write the failing test**

Create `test/docs.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "the nonexistent 'tour' command is referenced nowhere"
# docs/ is excluded: the spec and this plan discuss 'tour' by name.
hits=$(grep -rn '\btour\b' "$ROOT" \
        --exclude-dir=.git --exclude-dir=docs --exclude-dir=test 2>/dev/null | wc -l)
assert_equal "$hits" "0" "no tour references"

test_case "a gitignore exists"
[ -f "$ROOT/.gitignore" ]
assert_true $? "gitignore present"

test_case "gitignore blocks key material"
missing=0
for pattern in '*.asc' '*.pem' 'id_rsa*' '*.env' '*secret*' '*credential*'; do
  grep -qF "$pattern" "$ROOT/.gitignore" || { echo "    missing: $pattern"; missing=$((missing + 1)); }
done
assert_equal "$missing" "0" "all secret patterns present"

test_case "git actually ignores a dropped private key"
touch "$ROOT/test-fixture.pem"
git -C "$ROOT" check-ignore -q test-fixture.pem
result=$?
rm -f "$ROOT/test-fixture.pem"
assert_true "$result" "pem file is ignored"

test_case "both CLAUDE.md files name the same commands"
root_cmds=$(grep -o 'myenv\|tradecraft' "$ROOT/CLAUDE.md" | sort -u | tr '\n' ' ')
claude_cmds=$(grep -o 'myenv\|tradecraft' "$ROOT/.claude/CLAUDE.md" | sort -u | tr '\n' ' ')
assert_equal "$root_cmds" "$claude_cmds" "vocabularies match"

test_summary
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash test/docs.tests.sh`
Expected: FAIL — `tour` appears in `CLAUDE.md` (3×), and there is no `.gitignore`.

- [ ] **Step 3: Write the gitignore**

Create `.gitignore`:

```gitignore
# Key material. This repo is public: nothing here is negotiable.
*.asc
*.pem
*.ppk
*.key
*.p12
*.pfx
id_rsa*
id_ed25519*
*.gpg
known_hosts

# Credentials and tokens
.env
.env.*
*.env
*secret*
*credential*
*token*
wakatime.cfg
*firebase*.json

# Machine-local config that should not be shared
AMH2W-Profile-Config.json

# Binaries and archives - these belong in releases, not in a dotfiles repo
*.zip
*.exe
*.msi

# Scratch
tmp/
var/
*.log
```

- [ ] **Step 4: Remove every 'tour' reference**

In `CLAUDE.md`, line 6: `tour        # See installed tools and modern CLI alternatives` becomes `myenv       # See installed tools and modern CLI alternatives`. Line 19: ``Use `tour` instead of trial-and-error`` becomes ``Use `myenv` instead of trial-and-error``. Line 39: ``Efficiency (one `tour` not 10 guesses)`` becomes ``Efficiency (one `myenv` not 10 guesses)``.

The two `tour` references inside `shell/functions.sh` were removed in Task 8 when the hardcoded `tradecraft` body was replaced by `tradecraft.psv` — verify with `grep -n tour shell/functions.sh`, which must return nothing.

- [ ] **Step 5: Reconcile the CLAUDE.md files**

`.claude/CLAUDE.md` already says `myenv`; `CLAUDE.md` said `tour`. After Step 4 they agree. Also update `.claude/CLAUDE.md`'s "Key Domains" and environment description to say Windows-native daily driver with WSL2 for Linux-specific work, matching `tradecraft.psv`.

- [ ] **Step 6: Add the Windows quick start to README**

Under `## Quick Start`, before the existing `### WSL Ubuntu (Automated)` section:

````markdown
### Windows (Native)

```powershell
git clone https://github.com/guinetik/gui-dotfiles
cd gui-dotfiles
./powershell/install.ps1 -WhatIf   # see the plan
./powershell/install.ps1           # apply it
```

Installs amh2w if missing, hands `windows/packages.json` to
`all my homies bootstrap`, symlinks the profile drop-in, and makes
`myenv` and `tradecraft` available in every new shell.
````

- [ ] **Step 7: Run it to verify it passes**

Run: `bash test/docs.tests.sh`
Expected: `5 passed, 0 failed`.

- [ ] **Step 8: Checkpoint**

Run both runners. Report.

---

## Task 12: gui-configs migration

**Files:**
- Create: `windows/terminal/settings.json`, `windows/scripts/fix-ssh-permissions.ps1`, `windows/scripts/InstallFonts.ps1`, `common/install-docker-compose.sh`, `common/install-wakatime.sh`
- Test: `test/migration.tests.sh`

**Interfaces:**
- Consumes: the `.gitignore` from Task 11 (it must exist before any file is copied in).
- Produces: no code. Deliverable is that portable config lives here and no secret came with it.

**This task touches a second repository.** Files are copied in, verified, and only then removed from gui-configs — and that removal is left uncommitted for the owner to review.

- [ ] **Step 1: Write the failing test**

Create `test/migration.tests.sh`:

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

test_case "migrated files are present"
missing=0
for f in windows/terminal/settings.json \
         windows/scripts/fix-ssh-permissions.ps1 \
         windows/scripts/InstallFonts.ps1 \
         common/install-docker-compose.sh \
         common/install-wakatime.sh; do
  [ -f "$ROOT/$f" ] || { echo "    missing: $f"; missing=$((missing + 1)); }
done
assert_equal "$missing" "0" "all migrated files present"

test_case "no key material came across"
hits=$(find "$ROOT" -type f \
        \( -name '*.asc' -o -name '*.pem' -o -name 'id_rsa*' -o -name '*firebase*.json' \) \
        -not -path '*/.git/*' | wc -l)
assert_equal "$hits" "0" "no key files in the repo"

test_case "no file staged for commit is ignored-worthy"
hits=$(git -C "$ROOT" ls-files | grep -cE '\.(asc|pem|ppk|p12|pfx)$|id_rsa|firebase.*\.json')
assert_equal "$hits" "0" "no tracked secrets"

test_case "terminal settings are valid JSON"
pwsh -NoProfile -Command "Get-Content '$ROOT/windows/terminal/settings.json' -Raw | ConvertFrom-Json | Out-Null" 2>/dev/null
assert_true $? "settings.json parses"

test_summary
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash test/migration.tests.sh`
Expected: the first case FAILS — none of the files have been copied yet.

- [ ] **Step 3: Copy the portable files across**

```bash
mkdir -p windows/terminal windows/scripts
cp "D:/Developer/gui-configs/win/windows-terminal-settings.json" windows/terminal/settings.json
cp "D:/Developer/gui-configs/ssh/fix-ssh-permissions.ps1"        windows/scripts/
cp "D:/Developer/gui-configs/win/InstallFonts.ps1"               windows/scripts/
cp "D:/Developer/gui-configs/util/install-docker-compose.sh"     common/
cp "D:/Developer/gui-configs/util/install-wakatime.sh"           common/
```

Nothing else moves. `pgp/`, `ssh/` (other than the permissions script, which contains no key material), `backend/`, all binaries, and superseded legacy (`cmder/`, `p10k/`, `init5.*`, `oh-my-posh.json`) stay in gui-configs.

- [ ] **Step 4: Read each copied file before trusting it**

```bash
grep -rniE 'api[_-]?key|secret|token|password|BEGIN .*PRIVATE KEY' \
  windows/terminal windows/scripts common/install-docker-compose.sh common/install-wakatime.sh
```

Expected: no matches. If `install-wakatime.sh` contains a hardcoded API key, strip it and read the key from `$WAKATIME_API_KEY` instead. Do not commit anything this grep flags.

- [ ] **Step 5: Run it to verify it passes**

Run: `bash test/migration.tests.sh`
Expected: `4 passed, 0 failed`.

- [ ] **Step 6: Prune gui-configs, uncommitted**

Only after the tests above pass:

```bash
cd D:/Developer/gui-configs
git rm --cached win/windows-terminal-settings.json ssh/fix-ssh-permissions.ps1 \
                win/InstallFonts.ps1 util/install-docker-compose.sh util/install-wakatime.sh
git status
```

Leave it uncommitted. The owner reviews and commits. gui-configs is now secrets and binaries only — the state it needs to be in before its contents move to Bitwarden and the repo is deleted.

- [ ] **Step 7: Final checkpoint**

Run `bash test/run-all.sh` and `pwsh -NoProfile -File test/run-all.ps1`. Both must be fully green. Report:
- full output of `myenv` and `tradecraft` in pwsh,
- the renderer-agreement diff from Task 8,
- `git status` in both repos, staged by nobody.

---

## Deferred

Tracked in the spec's Open Items, deliberately out of scope here:

- Rotating the credentials exposed in gui-configs history.
- `install.sh` driving from `linux/packages.psv`, so the manifest and the 27 `common/install_*.sh` scripts stop being two lists of the same thing.
- Deleting gui-configs once Bitwarden holds its secrets.
- Porting `promptmode` / `toggleprompt` to PowerShell.
