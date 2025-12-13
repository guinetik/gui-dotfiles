# Custom shell functions
# This file is sourced by both .bashrc and .zshrc

# myenv - Display installed tools and environment setup
# Similar to neofetch but for your custom tooling setup
myenv() {
  local has_tool

  # Color codes
  local bold='\033[1m'
  local blue='\033[34m'
  local green='\033[32m'
  local yellow='\033[33m'
  local red='\033[31m'
  local reset='\033[0m'

  echo ""
  echo -e "${bold}${blue}╭─ My Environment (myenv) ─────────────────────╮${reset}"
  echo -e "${blue}│${reset}"

  # Modern CLI Tools Section
  echo -e "${blue}│${reset} ${bold}Modern CLI Tools (Replacements for GNU tools):${reset}"
  echo -e "${blue}│${reset}"

  # List of modern tools with descriptions
  local modern_tools=(
    "eza:Enhanced ls - colorful file listing with git integration"
    "bat:Syntax-highlighted cat with line numbers and themes"
    "rg:Ripgrep - blazingly fast grep alternative"
    "fd:Fast find command with simpler syntax"
    "dust:Disk usage analysis - prettier du alternative"
    "btm:Bottom - system monitor replacing top"
    "delta:Syntax-highlighted git diffs"
    "procs:Modern process viewer replacing ps"
    "bandwhich:Network bandwidth monitor"
    "tldr/tealdeer:Quick command documentation lookup"
  )

  for tool_info in "${modern_tools[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      local version=$(command -v "$tool_name" 2>/dev/null)
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Shell Enhancements Section
  echo -e "${blue}│${reset} ${bold}Shell Enhancements:${reset}"
  echo -e "${blue}│${reset}"

  local shell_tools=(
    "zoxide:Smart directory jumping (z command)"
    "atuin:Enhanced shell history with search and sync (Ctrl+R)"
    "starship:Fast, customizable prompt"
    "antidote:Zsh plugin manager"
  )

  for tool_info in "${shell_tools[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Editors & Development Section
  echo -e "${blue}│${reset} ${bold}Editors & Development:${reset}"
  echo -e "${blue}│${reset}"

  local dev_tools=(
    "nvim:Neovim - modern vim with Lua configuration"
    "lvim:LunarVim - Neovim-based IDE-like editor"
    "micro:Nano-like editor with modern features"
    "fzf:Fuzzy finder - for file/command searching"
    "qmd:QMD - local markdown search engine for knowledge management"
  )

  for tool_info in "${dev_tools[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Language Runtimes Section
  echo -e "${blue}│${reset} ${bold}Language Runtimes:${reset}"
  echo -e "${blue}│${reset}"

  local runtimes=(
    "node:Node.js (JavaScript/TypeScript runtime)"
    "bun:Bun (JavaScript/TypeScript runtime & package manager)"
    "python:Python"
    "cargo:Rust toolchain"
    "java:Java (via Jabba)"
    "go:Go (Golang)"
  )

  for tool_info in "${runtimes[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      local version=$($tool_name --version 2>/dev/null | head -1)
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Container & System Section
  echo -e "${blue}│${reset} ${bold}System & Containers:${reset}"
  echo -e "${blue}│${reset}"

  local sys_tools=(
    "docker:Docker container runtime"
    "ollama:Local LLM inference engine for embeddings and inference"
    "oxker:Docker TUI - interactive container manager"
    "nushell:Structured shell language (nu)"
  )

  for tool_info in "${sys_tools[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Multimedia & Document Tools Section
  echo -e "${blue}│${reset} ${bold}Multimedia & Documents:${reset}"
  echo -e "${blue}│${reset}"

  local multimedia_tools=(
    "ffmpeg:Video/audio processing and conversion"
    "convert:ImageMagick - image manipulation toolkit"
    "pdflatex:LaTeX - document preparation system"
  )

  for tool_info in "${multimedia_tools[@]}"; do
    IFS=':' read -r tool_name description <<< "$tool_info"
    if command -v "$tool_name" &> /dev/null; then
      echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${tool_name}${reset} - $description"
    else
      echo -e "${blue}│${reset}   ${red}✗${reset} ${tool_name} - $description"
    fi
  done

  echo -e "${blue}│${reset}"

  # Node.js Global Packages Section
  echo -e "${blue}│${reset} ${bold}Node.js Global Packages:${reset}"
  echo -e "${blue}│${reset}"

  if command -v npm &> /dev/null; then
    local npm_globals=(
      "branchlet:Git worktree manager"
      "claude:Claude Code CLI"
      "typescript:TypeScript compiler (tsc)"
      "nodemon:Auto-restart Node apps"
    )

    for pkg_info in "${npm_globals[@]}"; do
      IFS=':' read -r pkg_cmd description <<< "$pkg_info"
      if command -v "$pkg_cmd" &> /dev/null; then
        echo -e "${blue}│${reset}   ${green}✓${reset} ${bold}${pkg_cmd}${reset} - $description"
      else
        echo -e "${blue}│${reset}   ${red}✗${reset} ${pkg_cmd} - $description"
      fi
    done
  else
    echo -e "${blue}│${reset}   ${yellow}⚠${reset} Node.js/npm not installed - no global packages available"
  fi

  echo -e "${blue}│${reset}"
  echo -e "${blue}╰────────────────────────────────────────────────╯${reset}"
  echo ""
  echo -e "${yellow}Tip: Modern tools are installed but NOT aliased to GNU commands.${reset}"
  echo -e "${yellow}Use them directly by name (e.g., 'eza', 'rg', 'fd') when you want modern features.${reset}"
  echo -e "${yellow}Standard GNU tools (ls, grep, find, etc.) remain unmodified for compatibility.${reset}"
  echo -e "${yellow}Run 'myenv' anytime to check what's installed in your environment.${reset}"
  echo ""
}

# tradecraft - Display guinetik's working preferences and style
# Inspired by Severance: "Your outie likes to..."
# Reference this at the start of conversations to understand working preferences
tradecraft() {
  # Color codes
  local bold='\033[1m'
  local blue='\033[34m'
  local green='\033[32m'
  local yellow='\033[33m'
  local reset='\033[0m'

  echo ""
  echo -e "${bold}${blue}╭─ Tradecraft: Working with guinetik ──────────────────────╮${reset}"
  echo -e "${blue}│${reset}"

  # Technical Focus Section
  echo -e "${blue}│${reset} ${bold}Primary technical focus:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} Legacy code modernization (COBOL/CICS → Java microservices)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Agent-based systems and RAG architectures"
  echo -e "${blue}│${reset}   ${green}✓${reset} Graph algorithms and network analysis (worker-based compute)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Systems automation and DSL design (PowerShell, CLI tools)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Open-source: libraries and frameworks you actually use in production"
  echo -e "${blue}│${reset}   ${green}✓${reset} Interested in computer science education through practical projects"
  echo -e "${blue}│${reset}"

  # Philosophy Section
  echo -e "${blue}│${reset} ${bold}How they work:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} Architecture-first - designs constraints then delegates"
  echo -e "${blue}│${reset}   ${green}✓${reset} Leverage-based - systems where each part feeds the next"
  echo -e "${blue}│${reset}   ${green}✓${reset} Socratic - asks questions to guide thinking, not to impress"
  echo -e "${blue}│${reset}   ${green}✓${reset} Accessible - deliberately colloquial, anti-intellectual gatekeeping"
  echo -e "${blue}│${reset}   ${green}✓${reset} Pragmatic - shows value, not theory; efficiency is respect"
  echo -e "${blue}│${reset}"

  # Workflow Preferences Section
  echo -e "${blue}│${reset} ${bold}Your user prefers:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} NOT to commit code - that's their job, not yours"
  echo -e "${blue}│${reset}   ${green}✓${reset} To be asked before running builds (npm run build, mvn install, etc.)"
  echo -e "${blue}│${reset}     Builds waste time and tokens - ask first"
  echo -e "${blue}│${reset}   ${green}✓${reset} Efficiency over exploration - run 'myenv' instead of trial-and-error"
  echo -e "${blue}│${reset}   ${green}✓${reset} Modern CLI tools used explicitly (eza, rg, fd, not aliased to GNU)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Version managers for languages (nvm, pyenv, jabba, rustup)"
  echo -e "${blue}│${reset}"

  # Code Style Section
  echo -e "${blue}│${reset} ${bold}Your user values:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} Format on save (black, prettier, rustfmt)"
  echo -e "${blue}│${reset}   ${green}✓${reset} LSP-based development with proper linting (flake8, eslint, etc.)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Conventional commit messages (feat:, fix:, chore:, etc.)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Idempotent, modular scripts with error handling"
  echo -e "${blue}│${reset}   ${green}✓${reset} Clear, colored output in shell scripts"
  echo -e "${blue}│${reset}"

  # Communication Style Section
  echo -e "${blue}│${reset} ${bold}How your user thinks:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} Honesty over false positivity - be direct"
  echo -e "${blue}│${reset}   ${green}✓${reset} Practical efficiency explanations (not theoretical)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Minimal fluff, straight to the point"
  echo -e "${blue}│${reset}   ${green}✓${reset} Creative solutions and pragmatic thinking"
  echo -e "${blue}│${reset}"

  # Development Environment Section
  echo -e "${blue}│${reset} ${bold}Your user's ecosystem:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} WSL2 Ubuntu (guidev distro) on Windows"
  echo -e "${blue}│${reset}   ${green}✓${reset} Full-stack development: Java, Node.js, Python, Rust"
  echo -e "${blue}│${reset}   ${green}✓${reset} Primary project: Guinetik backend (/mnt/d/Developer/guinetik-backend)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Editors: LunarVim (development) + nano (quick edits) + IntelliJ"
  echo -e "${blue}│${reset}   ${green}✓${reset} Docker/containers for infrastructure"
  echo -e "${blue}│${reset}   ${green}✓${reset} Git with delta for syntax-highlighted diffs"
  echo -e "${blue}│${reset}"

  # Tools & Setup Section
  echo -e "${blue}│${reset} ${bold}Your user's setup:${reset}"
  echo -e "${blue}│${reset}"
  echo -e "${blue}│${reset}   ${green}✓${reset} Dotfiles repo: /mnt/d/Developer/gui-dotfiles (symlinked to home)"
  echo -e "${blue}│${reset}   ${green}✓${reset} Shell: Zsh with Starship prompt, Atuin history, Zoxide navigation"
  echo -e "${blue}│${reset}   ${green}✓${reset} Run 'tour' to see all installed modern tools and features"
  echo -e "${blue}│${reset}   ${green}✓${reset} Bitwarden Secrets Manager (BWS CLI) for credentials"
  echo -e "${blue}│${reset}"

  echo -e "${blue}╰──────────────────────────────────────────────────────────╯${reset}"
  echo ""
  echo -e "${yellow}💡 Work effectively by:${reset}"
  echo -e "${yellow}   • Understand constraints before proposing solutions${reset}"
  echo -e "${yellow}   • Be direct - honesty > flattery${reset}"
  echo -e "${yellow}   • Respect efficiency - use 'tour' instead of trial-and-error${reset}"
  echo -e "${yellow}   • Ask questions first, don't assume context${reset}"
  echo -e "${yellow}   • Treat them as domain expert who needs velocity${reset}"
  echo ""
}
