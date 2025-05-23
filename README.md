# My dotfiles

My personal dotfiles for getting a solid Linux development environment set up fast. Built for WSL Ubuntu but works on other distros too.

## What's included

This setup includes:

### **Shell Configuration**
- **[Zsh](https://www.zsh.org/)** with [Antidote](https://getantidote.github.io/) plugin manager
- **[Starship](https://starship.rs/)** prompt with git status, language versions, and system info
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** as fallback if Starship isn't available
- Shared aliases and functions for both bash and zsh

### **Modern CLI Tools**
Replacements for standard Unix tools:

- **[exa](https://github.com/ogham/exa)** → `ls` replacement with colors and git status
- **[bat](https://github.com/sharkdp/bat)** → `cat` replacement with syntax highlighting
- **[fd](https://github.com/sharkdp/fd)** → `find` replacement with simpler syntax
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** → `grep` replacement for fast code search
- **[procs](https://github.com/dalance/procs)** → `ps` replacement with better formatting
- **[dust](https://github.com/bootandy/dust)** → `du` replacement with visual output
- **[bottom](https://github.com/ClementTsang/bottom)** → `top` replacement for system monitoring
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** → smarter `cd` that learns your patterns
- **[bandwhich](https://github.com/imsnif/bandwhich)** → network monitoring
- **[tokei](https://github.com/XAMPPRocky/tokei)** → code statistics and line counting
- **[tealdeer](https://github.com/dbrgn/tealdeer)** → `tldr` command examples

### **Aliases and Commands**
Common aliases that work across both shells:

```bash
# Navigation
ls          # → exa 
ll          # → exa -la
lt          # → exa -T (tree view)
..          # → cd ..
...         # → cd ../..
z folder    # → jump to folder using zoxide
zz          # → go back to previous directory

# File operations  
cat file    # → bat with syntax highlighting
find name   # → fd
grep text   # → rg
du          # → dust
ps          # → procs
top         # → btm

# Development
rg pattern  # → search with smart case
rgf pattern # → search filenames only
rgh pattern # → include hidden files
netmon      # → network monitoring
```

### **Development Environments**
Version managers and tools for:

- **Java** → [Jabba](https://github.com/Jabba-Team/jabba) + [Maven](https://maven.apache.org/) + [Maven Daemon](https://github.com/apache/maven-mvnd)
- **Node.js** → [NVM](https://github.com/nvm-sh/nvm) + npm/yarn/pnpm
- **Python** → [pyenv](https://github.com/pyenv/pyenv) + [Poetry](https://python-poetry.org/) + [pipx](https://pypa.github.io/pipx/)
- **Rust** → [rustup](https://rustup.rs/) + cargo tools (edit, watch, audit, etc.)

### **Editor Setup**
- **[Neovim](https://neovim.io/)** (latest AppImage version)
- **[LunarVim](https://www.lunarvim.org/)** configuration
- LSP support for multiple languages
- [Telescope](https://github.com/nvim-telescope/telescope.nvim) for fuzzy finding
- Terminal integration

## Installation

Run the installation script:

```bash
git clone https://github.com/yourusername/gui-dotfiles.git
cd gui-dotfiles
./install.sh
```

The installer will prompt you to choose which components to install.

### Installation Options

1. **Essential tools** are installed automatically
2. **Modern CLI tools** - optional but recommended
3. **Development environments** - choose what you need
4. **Neovim + LunarVim** - optional
5. **Shell configuration** - creates symlinks for dotfiles

### Command Line Flags

```bash
./install.sh --force     # Reinstall everything
./install.sh --yolo      # Install everything without prompts
./install.sh --force --yolo  # Reinstall everything without prompts
```

## Supported Distros

- **Ubuntu/Debian** and friends (Pop!_OS, Mint, Elementary)
- **Arch** support coming eventually (PRs welcome)

## File Structure

```
gui-dotfiles/
├── bash/           # Bash configuration
├── zsh/            # Zsh configuration  
├── shell/          # Shared aliases and functions
├── git/            # Git configuration
├── starship/       # Starship prompt config
├── common/         # Shared installation scripts
├── dev/            # Development environment installers
│   ├── java/       # Java + Jabba + Maven
│   ├── node/       # Node.js + NVM + package managers
│   ├── python/     # Python + pyenv + tools
│   └── rust/       # Rust + rustup + cargo tools
└── distros/        # Distribution-specific stuff
    └── ubuntu/     # Ubuntu/Debian scripts
```

## Usage Examples

### **Directory Navigation**
```bash
z projects          # Jump to any directory containing "projects"
z gui dot           # Jump to "gui-dotfiles" directory
zi                  # Interactive directory picker with fzf
zz                  # Go back to previous directory
```

### **File Search & Content**
```bash
rg "function.*user"     # Find functions containing "user"
rg -t py "import"       # Search only Python files
fd "*.config"           # Find all .config files
bat config.yaml         # View file with syntax highlighting
```

### **Development Workflow**
```bash
# Java
jabba install openjdk@17    # Install Java 17
jabba use openjdk@17        # Switch to Java 17
mvn clean install          # Maven build (with daemon for speed)

# Node.js  
nvm install --lts          # Install latest LTS Node
npm install -g yarn pnpm   # Install package managers

# Python
pyenv install 3.11.7      # Install Python 3.11.7
pyenv global 3.11.7       # Set as default
poetry init                # Start new project

# Rust
cargo new my-project       # New Rust project
cargo watch -x run         # Watch for changes and run
cargo audit                # Check for security issues
```

## Customization

Everything's modular, change what you want:

- **Prompt**: Edit `starship/starship.toml` 
- **Aliases**: Add yours to `shell/aliases.sh`
- **Git**: Update `git/.gitconfig` with your info
- **Shell**: Tweak `zsh/.zshrc` or `bash/.bashrc`

## Why This Exists

This dotfiles setup automates the process of configuring a development environment with modern tools and sane defaults. It addresses common issues like:

- Session availability problems where tools install but aren't immediately usable
- Alias conflicts between different navigation tools
- Prompt conflicts between different shell prompts
- Verification failures during installation

The goal is to get from a fresh Linux installation to a fully configured development environment quickly and reliably.