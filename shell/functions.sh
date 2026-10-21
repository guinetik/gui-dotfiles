# Custom shell functions
# This file is sourced by both .bashrc and .zshrc

# _dotfiles_root - resolve the repo root, self-locating like PowerShell's
# Get-DotfilesRoot (powershell/functions.ps1).
# This file is installed as a SYMLINK at ~/.config/shell/functions.sh
# (see linux/links.psv) pointing into the repo checkout. Nothing on Linux
# ever sets $DOTFILES or populates $HOME/.config/gui-dotfiles, so falling
# back to that path unconditionally left myenv/tradecraft dead on any
# machine that didn't happen to export DOTFILES itself. Instead we resolve
# the symlink ${BASH_SOURCE[0]} to its real target (shell/functions.sh
# inside the repo) and go up one directory from that file to reach the
# repo root.
#
# The path is captured once, at source time: zsh has no BASH_SOURCE, and its
# equivalent (%x) means "this file" only while the file is being sourced, not
# later from inside a function. eval keeps bash from parsing the zsh syntax.
if [ -n "$ZSH_VERSION" ]; then
  eval '_DOTFILES_FUNCTIONS_SRC="${(%):-%x}"'
else
  _DOTFILES_FUNCTIONS_SRC="${BASH_SOURCE[0]}"
fi

_dotfiles_root() {
  if [ -n "$DOTFILES" ] && [ -d "$DOTFILES" ]; then
    printf '%s\n' "$DOTFILES"
    return 0
  fi

  local src="$_DOTFILES_FUNCTIONS_SRC"
  local resolved
  resolved="$(readlink -f "$src" 2>/dev/null)"
  if [ -z "$resolved" ]; then
    # readlink -f is a GNU/BSD-coreutils extension; macOS's stock readlink
    # doesn't support -f, so walk the symlink chain by hand instead.
    resolved="$src"
    while [ -L "$resolved" ]; do
      local link
      link="$(readlink "$resolved")"
      case "$link" in
        /*) resolved="$link" ;;
        *) resolved="$(dirname "$resolved")/$link" ;;
      esac
    done
  fi

  (cd "$(dirname "$resolved")/.." && pwd)
}

# myenv - Display installed tools and environment setup
# Catalog lives in linux/packages.psv or mac/packages.psv; detection happens at runtime.
myenv() {
  local bold='\033[1m' blue='\033[34m' green='\033[32m' yellow='\033[33m' red='\033[31m' reset='\033[0m'
  local root
  root="$(_dotfiles_root)"
  # One catalog per platform; same format, different tools.
  local platform=linux
  [ "$(uname -s)" = "Darwin" ] && platform=mac
  local psv="$root/$platform/packages.psv"

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
    if [ "$platform" = "mac" ]; then
      echo -e "${yellow}${missing} tool(s) missing. Run ./mac/install.sh to install them.${reset}"
    else
      echo -e "${yellow}${missing} tool(s) missing. Run ./install.sh to install them.${reset}"
    fi
  fi
  echo ""
}

# tradecraft - Display guinetik's working preferences and style
# Content lives in tradecraft.psv at the repo root, shared with PowerShell.
tradecraft() {
  local bold='\033[1m' blue='\033[34m' green='\033[32m' yellow='\033[33m' reset='\033[0m'
  local root
  root="$(_dotfiles_root)"
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

# promptmode - Toggle between minimal and full starship prompts
# Usage: promptmode [minimal|full|toggle]
promptmode() {
  local mode="${1:-toggle}"
  local minimal_config="$HOME/.config/starship-minimal.toml"

  # Color codes
  local green='\033[32m'
  local yellow='\033[33m'
  local reset='\033[0m'

  case "$mode" in
    minimal)
      export STARSHIP_CONFIG="$minimal_config"
      echo -e "${green}✓${reset} Switched to minimal prompt"
      ;;
    full)
      unset STARSHIP_CONFIG
      echo -e "${green}✓${reset} Switched to full Vercel-style prompt"
      ;;
    toggle)
      if [ "$STARSHIP_CONFIG" = "$minimal_config" ]; then
        unset STARSHIP_CONFIG
        echo -e "${green}✓${reset} Switched to full prompt"
      else
        export STARSHIP_CONFIG="$minimal_config"
        echo -e "${green}✓${reset} Switched to minimal prompt"
      fi
      ;;
    *)
      echo -e "${yellow}Usage:${reset} promptmode [minimal|full|toggle]"
      echo -e "  minimal - Switch to minimal prompt"
      echo -e "  full    - Switch to full Vercel-style prompt"
      echo -e "  toggle  - Toggle between modes (default)"
      return 1
      ;;
  esac

  # Reinitialize starship for current shell
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(starship init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(starship init bash)"
  fi

  # Show current prompt on next line
  echo -e "${yellow}New prompt will appear below:${reset}"
}

# Alias for convenience
alias toggleprompt='promptmode toggle'

# gclaude - Claude Code with the house defaults. Mirrors powershell/claude.ps1.
# `command` so a future alias or function named claude can't recurse into this.
gclaude() {
  CLAUDE_CODE_NO_FLICKER=1 command claude --dangerously-skip-permissions "$@"
}
