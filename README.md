# GUI Dotfiles

My personal dotfiles for getting a solid Linux development environment set up fast. Built for WSL Ubuntu but works on other distros too.

## Quick Start

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

### macOS (Apple Silicon)

```bash
xcode-select --install                     # if not already present
# install Homebrew from https://brew.sh
git clone https://github.com/guinetik/gui-dotfiles ~/Developer/gui-dotfiles
cd ~/Developer/gui-dotfiles
./mac/install.sh          # Brewfile, symlinks (mac/links.psv), mise runtimes
./mac/install.sh --ai     # also Ollama, LM Studio, MLX-LM
```

Runtimes come from [mise](https://mise.jdx.dev) (`mise/config.toml`) and
[uv](https://docs.astral.sh/uv/) rather than nvm/pyenv/jabba; containers from
OrbStack; terminal is Ghostty (`ghostty/config`). Anything a link would replace
is moved to `~/.dotfiles-backup/<timestamp>/` first. Machine-local secrets go
in `~/.zshrc.local`, which `.zshrc` sources and the repo never sees.

### WSL Ubuntu (Automated)

The fastest way to get started on WSL:

```powershell
# From PowerShell in the repository root
.\wsl\run.ps1 -DistroName "UbuntuDev" -TargetDirectory "D:\linux\ubuntu-dev"
```

See [wsl/README.md](wsl/README.md) for detailed WSL provisioning documentation.

### Manual Installation

```bash
git clone https://github.com/guinetik/gui-dotfiles.git ~/gui-dotfiles
cd ~/gui-dotfiles/distros/ubuntu
./install.sh
```

The installer will prompt you to choose which components to install.

## What's Included

### 🐚 Shell Configuration

- **[Zsh](https://www.zsh.org/)** with [Antidote](https://getantidote.github.io/) plugin manager
- **[Starship](https://starship.rs/)** prompt with git status, language versions, and system info
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** as fallback
- Shared aliases and functions for both bash and zsh
- **[Atuin](https://atuin.sh/)** - Magical shell history with sync and search (Ctrl+R)

### ⚡ Modern CLI Tools

Drop-in replacements for standard Unix tools with better UX:

| Old Command | New Tool | Description |
|-------------|----------|-------------|
| `ls` | **[eza](https://github.com/eza-community/eza)** | Modern ls with colors, icons, git status |
| `cat` | **[bat](https://github.com/sharkdp/bat)** | Syntax highlighting and git integration |
| `find` | **[fd](https://github.com/sharkdp/fd)** | Fast and user-friendly find |
| `grep` | **[ripgrep](https://github.com/BurntSushi/ripgrep)** | Ultra-fast recursive search |
| `cd` | **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter cd that learns your habits |
| `ps` | **[procs](https://github.com/dalance/procs)** | Modern process viewer |
| `du` | **[dust](https://github.com/bootandy/dust)** | Intuitive disk usage with graphs |
| `top` | **[bottom](https://github.com/ClementTsang/bottom)** | Graphical process/system monitor |
| `man` | **[tealdeer](https://github.com/dbrgn/tealdeer)** | Simplified tldr pages |

### 📊 Additional CLI Tools

- **[tokei](https://github.com/XAMPPRocky/tokei)** - Code statistics and line counting
- **[delta](https://github.com/dandavison/delta)** - Better git diffs with syntax highlighting
- **[bandwhich](https://github.com/imsnif/bandwhich)** - Network bandwidth monitor
- **[superfile](https://github.com/yorukot/superfile)** - Modern terminal file manager
- **[w3m](http://w3m.sourceforge.net/)** - Text-based web browser
- **[googler](https://github.com/jarun/googler)** - Google search from the terminal
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder with git integration

### 🛠️ Infrastructure & Services

- **[Docker](https://www.docker.com/)** - Container engine with Docker Compose plugin
- **[oxker](https://github.com/mrjackwills/oxker)** - TUI for Docker containers
- **[PowerShell](https://github.com/PowerShell/PowerShell)** (pwsh) - Cross-platform shell
- **[Bitwarden Secrets CLI](https://bitwarden.com/products/secrets-manager/)** (bws) - Secrets management
- **OpenSSH Server** - Remote access configuration

### 💻 Development Environments

Optional language-specific toolchains with version managers:

#### Java
- **[Jabba](https://github.com/Jabba-Team/jabba)** - Java version manager
- **[Maven](https://maven.apache.org/)** - Build tool
- **[Maven Daemon](https://github.com/apache/maven-mvnd)** - Faster Maven builds

#### Node.js
- **[NVM](https://github.com/nvm-sh/nvm)** - Node version manager
- **npm** - Package manager (comes with Node)
- Global packages: **[@anthropic-ai/claude-code](https://www.npmjs.com/package/@anthropic-ai/claude-code)**, **[branchlet](https://www.npmjs.com/package/branchlet)**

#### Python
- **[pyenv](https://github.com/pyenv/pyenv)** - Python version manager
- **[Poetry](https://python-poetry.org/)** - Dependency management
- **[pipx](https://pypa.github.io/pipx/)** - Install Python apps in isolated environments

#### Rust
- **[rustup](https://rustup.rs/)** - Rust toolchain installer
- **[cargo](https://doc.rust-lang.org/cargo/)** - Package manager and build tool
- Cargo extensions: edit, watch, audit, outdated, tree, etc.

### ✏️ Editors

- **[micro](https://micro-editor.github.io/)** - Modern terminal editor (easy to use)
- **[Neovim](https://neovim.io/)** - Hyperextensible Vim-based editor (latest stable)
- **[LunarVim](https://www.lunarvim.org/)** - Neovim IDE-like configuration with LSP
  - Pre-configured with Telescope, Treesitter, and LSP
  - Custom keybindings and theme
  - Ready for development out of the box

### 🔧 Utilities

- **Installation tracking system** - Prevents duplicate installations
- **Idempotent scripts** - Safe to run multiple times
- **Shared utility functions** - Package manager abstraction
- **Guinetik backend provisioning** - Custom environment setup

## Installation Options

### Command Line Flags

```bash
./install.sh              # Interactive installation
./install.sh --force      # Reinstall everything (ignores tracking)
./install.sh --yolo       # Install everything without prompts
./install.sh --force --yolo  # Nuclear option: reinstall all without prompts
```

### What Gets Installed

**Essential Tools** (always installed):
- Core packages (git, curl, wget, build-essential, etc.)
- eza, zoxide, ripgrep (modern CLI essentials)

**Optional Components** (prompted):
- Modern CLI tools (bat, fd, delta, procs, dust, bottom, etc.)
- Atuin (shell history), Starship (prompt)
- Superfile, w3m, googler, tokei
- Docker + Docker Compose
- PowerShell, Bitwarden CLI
- Development environments (Java, Node, Python, Rust)
- Editors (micro, Neovim + LunarVim)

**Configuration**:
- Shell configuration (zsh as default)
- Symlinks for dotfiles
- Guinetik backend environment (optional)

## Common Aliases

These work in both bash and zsh after installation:

```bash
# Navigation
ls          # → eza with icons
ll          # → eza -la (detailed list)
lt          # → eza -T (tree view)
..          # → cd ..
...         # → cd ../..
z folder    # → smart jump to folder
zi          # → interactive directory picker
zz          # → go back to previous directory

# File operations
cat file    # → bat (with syntax highlighting)
grep text   # → rg (ripgrep)
find name   # → fd (faster find)
du          # → dust (visual disk usage)
ps          # → procs (modern process viewer)
top         # → btm (bottom system monitor)

# Search patterns
rg pattern          # → smart case search
rgf pattern         # → search filenames only
rgh pattern         # → include hidden files
rgi pattern         # → case insensitive

# Development
dockerc             # → docker compose (or docker-compose)
mvnw                # → Maven wrapper
poetry run          # → Run in Poetry virtualenv
cargo watch -x run  # → Auto-rebuild Rust project

# Git (with delta for better diffs)
git diff            # → Shows with syntax highlighting
git log             # → Pretty formatted with delta

# System
netmon              # → bandwhich network monitor
tokei               # → Code statistics
```

## File Structure

```
gui-dotfiles/
├── bash/              # Bash configuration
├── zsh/               # Zsh configuration
├── shell/             # Shared aliases and functions
│   └── lib/           # Shared psv.sh parser sourced by shell/functions.sh
├── git/               # Git configuration
├── starship/          # Starship prompt config
├── micro/             # Micro editor settings
├── nvim/              # Neovim configuration
│   └── lunarvim/      # LunarVim config
├── common/            # Cross-distro installation scripts
│   ├── utils.sh       # Shared utilities
│   ├── pkg_manager.sh # Package manager abstraction
│   ├── install_*.sh   # Individual tool installers
│   └── ...
├── dev/               # Development environment installers
│   ├── java/          # Java + Jabba + Maven
│   ├── node/          # Node.js + NVM
│   ├── python/        # Python + pyenv + Poetry
│   └── rust/          # Rust + rustup + cargo
├── distros/           # Distribution-specific scripts
│   └── ubuntu/        # Ubuntu/Debian
│       ├── install.sh # Main installer
│       └── scripts/   # Ubuntu-specific scripts
├── linux/             # Linux link map and package catalog (links.psv, packages.psv)
├── powershell/        # Windows shell: profile drop-ins, installer, and lib/ helpers (links, manifest, psv, render)
├── windows/           # Windows link map, package manifest, Terminal settings, and provisioning scripts
├── test/              # Bash + PowerShell test suites, run via run-all.sh / run-all.ps1, plus parity.sh
├── docs/              # Superpowers plans and specs for this repo's design work
├── tradecraft.psv     # Working-preferences data, shared by shell/functions.sh and powershell/functions.ps1
└── wsl/               # WSL provisioning automation
    ├── run.ps1        # PowerShell provisioning script
    └── README.md      # WSL-specific documentation
```

## Usage Examples

### Directory Navigation with zoxide

```bash
# After visiting directories, zoxide learns your habits
z dev              # Jump to ~/Developer
z gui dot          # Jump to ~/gui-dotfiles
z proj api         # Jump to ~/projects/my-api
zi                 # Interactive fuzzy search
zz                 # Go back
```

### File Search & Content

```bash
# Search code with ripgrep
rg "function.*user"           # Find functions with "user"
rg -t py "import"             # Search only Python files
rg -t js "const.*API"         # Search JavaScript for API constants
rg --hidden "config"          # Include hidden files

# Find files with fd
fd "*.config"                 # All .config files
fd -e py                      # All Python files
fd -H .env                    # Find .env (including hidden)

# View files with syntax highlighting
bat config.yaml               # Pretty print YAML
bat src/main.rs               # Rust with syntax highlighting
bat -n script.sh              # With line numbers
```

### Shell History with Atuin

```bash
# Press Ctrl+R for interactive history search
# Features:
# - Fuzzy search across all history
# - Context-aware (understands current directory)
# - Optional sync across machines
# - Stats and insights

atuin search git              # Search history for git commands
atuin stats                   # Show history statistics
```

### Development Workflow

```bash
# Java
jabba install openjdk@17      # Install Java 17
jabba use openjdk@17          # Switch to Java 17
mvn clean install             # Maven build (with daemon)

# Node.js
nvm install --lts             # Install latest LTS
nvm install 18                # Install Node 18
nvm use 18                    # Switch to Node 18
npm install -g yarn pnpm      # Install package managers

# Python
pyenv install 3.11.7          # Install Python 3.11.7
pyenv global 3.11.7           # Set as default
poetry init                   # Start new project
poetry add requests           # Add dependency
poetry run python app.py      # Run in virtualenv

# Rust
cargo new my-project          # New Rust project
cargo watch -x run            # Auto-rebuild on changes
cargo audit                   # Security check
cargo tree                    # Dependency tree
```

### Docker Management

```bash
# Docker with compose plugin
docker compose up -d          # Start services
docker compose logs -f        # Follow logs

# Oxker TUI
oxker                         # Launch Docker container manager
# Navigate with arrows, view logs, restart containers, etc.
```

### System Monitoring

```bash
btm                           # Launch bottom (better top)
# Navigate with arrow keys, view CPU, memory, network, processes

dust                          # Visual disk usage
dust -d 2                     # Limit depth to 2 levels

procs                         # Modern process viewer
procs firefox                 # Filter by name
procs --tree                  # Show process tree
```

## WSL-Specific Features

The `wsl/` directory contains automation for Windows Subsystem for Linux:

- **Automated distro creation** from Ubuntu Jammy Core image
- **User configuration** with customizable username/password
- **NOPASSWD sudo setup** for seamless installations
- **Repository linking** from Windows to WSL
- **Line ending conversion** (CRLF → LF)
- **Full provisioning** in one command

See [wsl/README.md](wsl/README.md) for complete WSL documentation.

## Supported Distributions

- ✅ **Ubuntu 22.04 (Jammy)** and newer - Fully supported
- ✅ **Debian** and derivatives (Pop!_OS, Linux Mint, Elementary)
- ✅ **WSL2** - Optimized with automated provisioning
- 🚧 **Arch Linux** - Planned (PRs welcome)
- 🚧 **Fedora** - Planned (PRs welcome)

## Customization

Everything's modular. Customize what you want:

### Shell & Prompt
- **Prompt**: Edit `starship/starship.toml`
- **Aliases**: Add yours to `shell/aliases.sh`
- **Zsh config**: Modify `zsh/.zshrc`
- **Bash config**: Modify `bash/.bashrc`

### Editor Configuration
- **Micro**: `micro/settings.json`
- **Neovim**: `nvim/init.lua`
- **LunarVim**: `nvim/lunarvim/config.lua`

### Git Configuration
Update `git/.gitconfig` with your info:

```bash
[user]
    name = Your Name
    email = your.email@example.com
```

### Development Environments
Each dev environment has its own `install.sh` in `dev/<language>/`:
- Add tools to `dev/rust/install_cargo_tools.sh`
- Add npm packages to `common/install_npm_global_packages.sh`
- Add Python tools to `dev/python/install_python_tools.sh`

## Troubleshooting

### Installation Issues

**Scripts fail with "bad interpreter"**
```bash
# Line ending issues (CRLF vs LF)
find . -name "*.sh" -exec dos2unix {} \;
```

**"command not found" after installation**
```bash
# Reload your shell configuration
source ~/.bashrc   # or ~/.zshrc
# Or restart your terminal
```

**Package installation hangs**
- The scripts now show real-time progress for apt installations
- If truly stuck, press Ctrl+C and re-run

**Permission denied errors**
```bash
# Make scripts executable
chmod +x distros/ubuntu/install.sh
chmod +x common/*.sh
```

### Tool-Specific Issues

**zoxide not working**
```bash
# Ensure it's in PATH
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

**Docker permissions**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

**Neovim/LunarVim errors**
- Make sure all LSPs are installed: `:LvimInfo`
- Update plugins: `:LvimUpdate`
- Check logs: `~/.local/state/lvim/lsp.log`

### WSL-Specific Issues

See detailed troubleshooting in [wsl/README.md](wsl/README.md), including:
- WSL installation issues
- Sudo configuration
- Line ending problems
- Network issues
- And more

## Why This Exists

This dotfiles repository solves common pain points in Linux development environment setup:

### Problems Solved

1. **Manual Configuration Tedium** - Hours of `apt install`, configuration, and setup
2. **Tool Discoverability** - Finding and testing modern CLI alternatives
3. **Reproducibility** - Consistent environment across machines
4. **Session Availability** - Tools install but aren't immediately usable
5. **Idempotence** - Scripts fail when run twice
6. **WSL Pain Points** - Line endings, sudo, Windows/Linux interop

### Design Principles

- **Idempotent**: Safe to run scripts multiple times
- **Modular**: Install only what you need
- **Tracked**: Knows what's installed to avoid duplicates
- **Cross-distro**: Abstracts package managers
- **Modern**: Uses contemporary tools with better UX
- **Documented**: Clear documentation and examples

## Contributing

Contributions welcome! Areas of interest:

- **Arch Linux support** - Package manager mappings
- **Fedora/RHEL support** - DNF package mappings
- **More dev environments** - Go, Ruby, PHP, etc.
- **Tool suggestions** - Modern CLI tools we're missing
- **Bug fixes** - Installation issues, path problems

## License

MIT License - Use freely, modify as needed.

## Acknowledgments

Inspired by the dotfiles community and countless hours of environment configuration. Special thanks to the maintainers of all the amazing modern CLI tools that make this setup possible.
