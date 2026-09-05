# Windows Dotfiles Unification — Design

**Date:** 2026-09-04
**Status:** Approved, pending implementation plan

## Problem

This repo was built when Claude Code ran only under WSL, so its shell layer is
Linux-shaped: `install.sh`, `common/*.sh`, and `shell/functions.sh` assume bash
or zsh on Ubuntu. Windows is now the daily driver — the native binary removed
the reason to develop inside WSL, where cross-filesystem file access cost real
time.

The utilities drifted as a result:

- `myenv` and `tradecraft` exist only as bash functions in `shell/functions.sh`.
  They are unreachable from PowerShell, and unreachable from Claude Code's Bash
  tool (non-interactive shells never source `.bashrc`).
- `tour` is referenced five times — `CLAUDE.md` lines 6, 19, 39, and inside
  `tradecraft`'s own output at `shell/functions.sh:280,289` — and defined
  nowhere. A rename from `myenv` to `tour` was started and abandoned.
- `tradecraft`'s output still describes the WSL era: "WSL2 Ubuntu (guidev
  distro)" as the ecosystem, `/mnt/d/Developer/guinetik-backend` as the primary
  project, `/mnt/d/Developer/gui-dotfiles` as the dotfiles repo.

Two adjacent repos overlap with this one:

- **`D:\Developer\gui-configs`** (private) — the original dotfiles repo, from
  before the convention was called dotfiles. It mixes portable config with
  credentials committed to git history.
- **`D:\Developer\amh2w`** (public) — a PowerShell DSL that already provisions
  Windows machines from a package manifest.

## Goals

1. `myenv` and `tradecraft` work natively in PowerShell 7 on Windows.
2. This repo becomes the single home for both Linux and Windows dotfiles.
3. Windows provisioning delegates to amh2w rather than reimplementing it.
4. Portable config migrates out of gui-configs, leaving it as a secrets vault
   to be emptied into Bitwarden and deleted later.
5. Drift becomes structurally harder: content that is genuinely shared lives in
   one file.

## Non-goals

- Rotating the credentials currently exposed in gui-configs history. Necessary,
  tracked separately.
- Moving secrets into Bitwarden. `guinetik-backend` already has a mature `bws`
  setup; that migration is its own job.
- Deleting gui-configs. It stays until its secrets are relocated.
- Porting `promptmode` / `toggleprompt` to PowerShell. Starship on Windows is
  configured through the profile, not through `STARSHIP_CONFIG` toggling.
- Rewriting `install.sh` to be manifest-driven. Identified as a follow-on; see
  Phase 2 notes.

## Constraints discovered

These were verified in-session, not assumed.

**`gui-dotfiles` is public and has no `.gitignore`.**
Remote is `git@github.com:guinetik/gui-dotfiles.git`. Nothing is currently
ignored. Any migration must treat secret material as a hard boundary, and must
not merge gui-configs history, which contains:

```
pgp/guinetik@gmail.com.private.asc      PGP private key
ssh/vultr/email@guinetik.com            SSH private key
ssh/guinetik@gmail.com.zip              SSH key archive
ssh/vercel-recovery-codes.txt           recovery codes
backend/guinetik-backend-firebase.json  service account
```

**amh2w's bootstrap already accepts an external manifest.**
`all/my/homies/bootstrap.ps1` is declared as
`bootstrap([string]$PackageFile = "$PSScriptRoot\packages.json", [object]$Yolo)`.
It parses `{ category: [ { name, description, command } ] }`, self-elevates
when not admin, and prompts per package unless `$Yolo`. It reads those three
properties off a `PSCustomObject`, so **additional JSON fields are ignored**.
This repo can ship its own manifest and call amh2w unmodified.

**amh2w is not on PSGallery and has no module manifest.**
Installation is: clone the repo, run its `install.ps1`, which copies `core/`
and `all/` into the first `$env:PSModulePath` entry. Our installer must do the
same rather than `Install-Module`.

**Windows Developer Mode is enabled.**
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowDevelopmentWithoutDevLicense = 1`,
so `New-Item -ItemType SymbolicLink` works unelevated. The Windows arm can use
real symlinks, matching Linux, instead of copying files and requiring a re-run
of the installer after every edit.

**The PowerShell profile already has a load hook.**
`Documents\PowerShell\Microsoft.PowerShell_profile.ps1` dot-sources every
top-level `.ps1` in `Documents\PowerShell\drop-ins\`, alphabetically, last, when
`Dropins` is true in `AMH2W-Profile-Config.json`. It is currently true. No
profile surgery is needed.

**`convert` is a false positive on Windows.**
`convert` resolves to `C:\WINDOWS\system32\convert.exe`, the NTFS filesystem
converter. A naive port of the bash tool list would report ImageMagick as
installed when it is not. The correct probe is `magick`.

**Windows tool audit.** Present: `rg`, `zoxide`, `starship`, `nvim`, `node`
(nvm4w), `bun`, `python`/`python3`/`pip` (pyenv-win), `py`, `uv`, `cargo`,
`rustup`, `rustc`, `docker`, `ffmpeg`, `magick`, `npm`, `branchlet`, `claude`,
`tsc`, `pwsh`, `powershell`, `winget`, `scoop`, `choco`, `git`, `gh`, `wsl`,
`wt`, `pnpm`, `dotnet`, `mvn`, `code`, `curl`, `jq`, `7z`, `ssh`, `bws`,
`gitui`. Modules: PSReadLine 2.4.5, Terminal-Icons 0.11.0, AMH2W 1.0.4.
Absent, though present in the bash list: `eza`, `bat`, `fd`, `dust`, `btm`,
`delta`, `procs`, `bandwhich`, `tldr`, `atuin`, `antidote`, `fzf`, `lvim`,
`micro`, `qmd`, `ollama`, `oxker`, `nu`, `java`, `go`, `pdflatex`. Also absent:
`jabba`, despite the profile attempting to load it.

## Approaches considered

**A. Platform-partitioned tree** (`linux/`, `windows/`, `shared/`). Rejected.
The tool configs — `nvim/`, `starship/`, `git/`, `micro/`, `oxker/` — are
identical on both platforms; only the link target differs. Partitioning by
platform either duplicates them or drains everything meaningful into `shared/`,
leaving the platform directories holding installers alone. It also breaks every
path in `install.sh` for no gain.

**B. Tool-named tree plus a Windows arm.** Minimal churn, nothing breaks. But
the link map stays hardcoded in bash while a second one is hardcoded in
PowerShell — reproducing exactly the drift being fixed.

**C. Tool-named tree plus extracted data files.** Selected. Configs stay in
tool-named directories. The two platform-specific concerns — what to install,
and where files link — move out of the scripts and into data files, in a format
each consumer reads natively.

## Design

### Shared vs. per-platform data

An earlier draft proposed one cross-platform manifest for both shells. That was
wrong. Package lists are inherently per-platform: `winget install Git.Git` and
`apt install git` share a word, not a record. A single schema for both produces
a file half-empty on each side. The drift that actually occurred was in prose —
`tour`, the WSL-era ecosystem text — not in the tool list.

So exactly one file is genuinely shared, and it is the one that broke.

| File | Format | Consumers | Rationale |
|---|---|---|---|
| `tradecraft.psv` | pipe-delimited | bash, pwsh | Identical text on both platforms |
| `windows/packages.json` | JSON (amh2w schema) | amh2w bootstrap, pwsh `myenv` | amh2w mandates JSON; pwsh parses natively |
| `linux/packages.psv` | pipe-delimited | bash `myenv` | bash has no JSON parser; avoids a hard `jq` dependency |
| `linux/links.psv` | pipe-delimited | `create_symlinks.sh` | Extracted from the inline array |
| `windows/links.psv` | pipe-delimited | `install.ps1` | Same map, Windows targets |

No `jq` dependency, no JSON parsing in bash, no generated files.

### Pipe-delimited format

Chosen because bash parses it with `IFS='|' read` and PowerShell with
`ConvertFrom-Csv -Delimiter '|'`, with zero dependencies on either side.

`tradecraft.psv`:

```
@title|Tradecraft: Working with guinetik
@section|Primary technical focus
-|Legacy code modernization (COBOL/CICS -> Java microservices)
-|Agent-based systems and RAG architectures
@section|Your user's ecosystem
-|Windows 11 native daily driver (pwsh 7 + Windows Terminal)
-|WSL2 'guidev' for Linux-specific work, not general development
@tip|Be direct - honesty > flattery
```

`linux/packages.psv`:

```
@section|Modern CLI Tools (Replacements for GNU tools)
eza|Enhanced ls - colorful file listing with git integration
rg|Ripgrep - blazingly fast grep alternative
```

`links.psv` (both platforms), `source|target`:

```
shell/functions.sh|$HOME/.config/shell/functions.sh
powershell/dotfiles.ps1|$HOME/Documents/PowerShell/drop-ins/00-gui-dotfiles.ps1
```

Targets are expanded by the consuming shell. Lines starting with `#` and blank
lines are ignored.

### packages.json schema

amh2w's three fields plus two additive ones it will ignore:

```json
{
  "name": "neovim",
  "description": "Neovim - modern vim with Lua configuration",
  "command": "scoop install neovim",
  "check": "nvim"
}
```

- **`check`** — the binary `myenv` probes. When absent, the entry is a
  provisioning *step*, not a tool, and `myenv` skips it. This excludes
  `winget-upgrade` and `chocolatey-core-extension` from the display without a
  special case.
- **`checkType`** — `command` (default) or `module`. `module` entries are
  probed with `Get-Module -ListAvailable`, covering PSReadLine, Terminal-Icons,
  and AMH2W itself.

`check` is also where the ImageMagick problem is solved: name `imagemagick`,
check `magick`, never `convert`.

Scope is **dev-machine only** — no browsers, Slack, Discord, Steam, Spotify.
Those stay in amh2w's own default manifest, run separately when setting up a
machine for daily use rather than for development.

The manifest is seeded from the audit above, and includes entries for tools that
are *not* installed but should be, each with a working `command`. `myenv` then
doubles as the to-do list, and `bootstrap` is how it gets cleared.

Categories: `core`, `cli`, `shell`, `editors`, `runtimes`, `containers`,
`media`, `security`, `node-globals`, `powershell-modules`.

### Windows arm

**`powershell/functions.ps1`** — `myenv` and `tradecraft` as bare-name
functions, matching the bash names exactly. ANSI colors and box-drawing output
matching the bash renderer.

- `myenv` reads `$env:DOTFILES\windows\packages.json`, groups by category, and
  probes each entry's `check` at runtime via `Get-Command` or
  `Get-Module -ListAvailable`. Nothing is cached; detection is always live.
- `tradecraft` renders `tradecraft.psv`.

**`powershell/dotfiles.ps1`** — the drop-in. Sets `$env:DOTFILES` for the
session and dot-sources `functions.ps1` from the repo, so repo edits take effect
in the next shell with no reinstall.

**`powershell/install.ps1`** — supports `-WhatIf` to print the plan without
applying it.

1. Require PowerShell 7. Resolve the repo root; set `DOTFILES` as a persistent
   user environment variable.
2. Ensure amh2w: if `Get-Module -ListAvailable AMH2W` finds nothing, clone
   `https://github.com/guinetik/amh2w` beside this repo and run its
   `install.ps1`.
3. `all my homies bootstrap "$env:DOTFILES\windows\packages.json"` — amh2w
   handles elevation and per-package prompting.
4. Apply `windows/links.psv` as symlinks.
5. Ensure `drop-ins/` exists and `Dropins` is true in
   `AMH2W-Profile-Config.json`.

The existing `drop-ins\guinetik.ps1` is the user's own file and is not touched,
except that the hardcoded `D:\Developer\gui-dotfiles` in its `gclaude` function
can become `$env:DOTFILES`. Drop-ins load alphabetically, so ours is prefixed
`00-` to load first.

### Linux arm

Behavior unchanged; data extracted.

- `common/create_symlinks.sh` reads `linux/links.psv` instead of its inline
  `SYMLINKS` array.
- `shell/functions.sh`'s `myenv` renders `linux/packages.psv`.
- `tradecraft` renders `tradecraft.psv`.
- `promptmode` and `toggleprompt` are untouched.

Follow-on, not in this scope: `install.sh` should eventually drive from
`linux/packages.psv` too, so the manifest and the 27 `common/install_*.sh`
scripts stop being two lists of the same thing.

### gui-configs migration

Fresh files, no history merge.

**Moves:**

| From | To |
|---|---|
| `win/windows-terminal-settings.json` | `windows/terminal/settings.json` |
| `ssh/fix-ssh-permissions.ps1` | `windows/scripts/fix-ssh-permissions.ps1` |
| `win/InstallFonts.ps1` | `windows/scripts/InstallFonts.ps1` |
| `win/packages.txt` | seed for `windows/packages.json`, then dropped |
| `util/install-docker-compose.sh` | `common/` |
| `util/install-wakatime.sh` | `common/` |

`util/install-node-debian.sh`, `install-openjdk.sh`, and `install-rust-wsl.sh`
are not moved; `common/` already covers those better.

**Stays behind:** `pgp/`, `ssh/`, `backend/`; binaries (`idea/*.zip`, `*.exe`,
`vlc/skins`, `nerdfonts/`); superseded legacy (`cmder/`, `p10k/`, `init5.*`,
`oh-my-posh.json`, msys2 and zsh-on-Windows scripts) — starship and native pwsh
replaced all of it.

`util/wakatime.cfg` is presumed to contain an API key and is left behind; the
new `.gitignore` covers the filename regardless.

The end state is gui-configs holding secrets and binaries only — the shape it
needs to be in before the Bitwarden migration and its eventual deletion.

### Hygiene and docs

**New `.gitignore`**, deliberately aggressive:

```
*.asc  *.pem  *.ppk  *.key  *.p12  *.pfx
id_rsa*  id_ed25519*
.env  .env.*  *.env
*secret*  *credential*  *token*
wakatime.cfg
AMH2W-Profile-Config.json
*.zip
```

**`tour` is removed** from all five references and replaced with `myenv`:
`CLAUDE.md` lines 6, 19, 39 and `shell/functions.sh` lines 280, 289.

**`tradecraft` content is rewritten** for the current reality: Windows-native
daily driver, `D:\Developer\...` paths, WSL2 `guidev` demoted to Linux-specific
work.

**`CLAUDE.md` and `.claude/CLAUDE.md` are reconciled** to one vocabulary — they
currently disagree, one saying `tour` and the other `myenv`.

**README** gains a Windows quick start alongside the WSL one.

## Testing

- `myenv` in pwsh, checked line by line against the audit in this document. The
  specific regression to watch: ImageMagick must not show as installed via
  `convert`.
- `tradecraft` in pwsh and in bash from the same `tradecraft.psv`, confirming
  both renderers agree.
- `install.ps1 -WhatIf` prints the full link plan and touches nothing.
- `create_symlinks.sh` after the data extraction produces the same links as the
  current inline array.
- `grep -rn "\btour\b" --exclude-dir=docs --exclude-dir=.git .` returns nothing.
  (This spec is excluded — it discusses `tour` by name.)

## Phases

1. **Windows arm.** All new files; nothing existing can break. Immediately
   verifiable by running `myenv` in pwsh.
2. **Linux data extraction.** `links.psv`, `packages.psv`, shared
   `tradecraft.psv`; bash output must be unchanged from today.
3. **gui-configs migration, `.gitignore`, docs reconciliation.**

## Open items

- Credential rotation for the keys exposed in gui-configs history.
- `install.sh` driving from `linux/packages.psv`.
- Deleting gui-configs once Bitwarden holds its secrets.
