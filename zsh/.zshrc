# Only enable Powerlevel9k if starship is not available
if ! command -v starship &> /dev/null; then
  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
else
  # Disable P10k configuration wizard since we're using starship
  POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
fi

# .zshrc - Zsh Configuration File

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify

# Basic zsh options
setopt autocd
setopt extended_glob
setopt nomatch
setopt notify
unsetopt beep
bindkey -e  # Use emacs key bindings

# Load colors for the terminal
autoload -U colors && colors

# Set up Antidote (Plugin Manager)
ANTIDOTE_HOME="$HOME/.antidote"
if [[ ! -d $ANTIDOTE_HOME ]]; then
  echo "Antidote not found. Installing..."
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ANTIDOTE_HOME}
fi

# Set ZSH_CACHE_DIR for Oh-My-Zsh plugins compatibility
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

source ${ANTIDOTE_HOME}/antidote.zsh

# Load plugins (static)
if [[ -f ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh ]]; then
  source ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
# If static file doesn't exist, generate it
elif [[ -f ${ZDOTDIR:-$HOME}/.zsh_plugins.txt ]]; then
  echo "Generating static plugins file..."
  antidote bundle < ${ZDOTDIR:-$HOME}/.zsh_plugins.txt > ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
  source ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
fi

# Note: If you encounter conflicts with 'z' command, remove ~/.zsh_plugins.zsh to regenerate

# Load Powerlevel10k as fallback if starship is not available
if ! command -v starship &> /dev/null; then
  antidote load romkatv/powerlevel10k
fi

# Add custom completion functions directory
fpath=(~/.zfunc $fpath)

# Completion system initialization (should be after plugin loading)
autoload -Uz compinit
compinit

# Prompt - Use starship if available
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
else
  # Basic prompt if starship isn't available
  PROMPT="%B%F{green}%n@%m%f%b:%B%F{blue}%~%f%b$ "
fi

# Enable correction
setopt correct

# Source shared aliases
if [ -f "$HOME/.config/shell/aliases.sh" ]; then
  source "$HOME/.config/shell/aliases.sh"
fi

# Source shared functions
if [ -f "$HOME/.config/shell/functions.sh" ]; then
  source "$HOME/.config/shell/functions.sh"
fi

# Zoxide (better cd)
# Smart directory jumping with 'z' command
# Must be loaded after compinit
if command -v zoxide &> /dev/null; then
  # Fix for old zoxide versions: define _z_cd before eval to avoid recursion
  _z_cd() {
    builtin cd "$@" || return "$?"
    if [ "$_ZO_ECHO" = "1" ]; then
      echo "$PWD"
    fi
  }
  # Load zoxide but skip the broken _z_cd definition
  eval "$(zoxide init zsh | sed '/_z_cd()/,/^}/d')"
fi

# Basic directory navigation aliases (in addition to shared ones)
alias ..='cd ..'
alias ...='cd ../..'

# ---- FZF Configuration ----
# FZF key bindings and completion are loaded via junegunn/fzf plugin in .zsh_plugins.txt
# This provides Ctrl+T, Ctrl+R, and Alt+C shortcuts, plus ** tab completion

# Use fd instead of find for FZF
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  # Use fd for path completion
  _fzf_compgen_path() {
    fd --hidden --exclude .git . "$1"
  }

  # Use fd for directory completion
  _fzf_compgen_dir() {
    fd --type=d --hidden --exclude .git . "$1"
  }
fi

# FZF + bat/eza previews
if command -v fzf &> /dev/null; then
  # Determine which commands are available
  local preview_file="cat {}"
  local preview_dir="ls -la {}"

  if command -v bat &> /dev/null || command -v batcat &> /dev/null; then
    local bat_cmd=$(command -v bat 2>/dev/null || command -v batcat 2>/dev/null)
    preview_file="$bat_cmd -n --color=always --line-range :500 {}"
  fi

  if command -v eza &> /dev/null; then
    preview_dir="eza --tree --color=always {} | head -200"
  elif command -v exa &> /dev/null; then
    preview_dir="exa --tree --color=always {} | head -200"
  fi

  show_file_or_dir_preview="if [ -d {} ]; then $preview_dir; else $preview_file; fi"

  export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
  export FZF_ALT_C_OPTS="--preview '$preview_dir'"

  # Advanced customization of fzf options via _fzf_comprun function
  _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
      cd)           fzf --preview "$preview_dir" "$@" ;;
      export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
      ssh)          fzf --preview 'dig {}'                   "$@" ;;
      *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
    esac
  }
fi

# FZF + Git integration
if [ -f "$HOME/.local/share/fzf-git.sh/fzf-git.sh" ]; then
  source "$HOME/.local/share/fzf-git.sh/fzf-git.sh"
fi

# bat (better cat) - handle Ubuntu's batcat naming
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
  alias bat='batcat'
fi

# ---- Atuin (shell history management) ----
# Atuin provides enhanced shell history with sync, search, and statistics
# Ctrl+R: Open atuin fuzzy history search
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
fi

# Development environment setup

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv (Python Version Manager)
# Only use Linux pyenv, not Windows pyenv-win in WSL
if [ -d "$HOME/.pyenv" ] && [ -f "$HOME/.pyenv/bin/pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Jabba (Java Version Manager)
[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Local bin directory
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Custom functions

# Reload zsh configuration
newsession() {
  source ~/.zshrc
  echo "✓ Zsh configuration reloaded"
}

# Create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract common archive formats
extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Interactive way to choose commands from history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# Load custom user configurations if they exist
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# Only load P10k config if starship is not available
if ! command -v starship &> /dev/null; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

# Guinetik backend configuration is managed by install_guinetik.sh
# Run: ~/gui-dotfiles/common/install_guinetik.sh to configure
# BEGIN GUINETIK CONFIG
# Guinetik Backend Configuration
# Generated by install_guinetik.sh

# Project root directory
export GUINETIK_ROOT="/mnt/d/Developer/guinetik-backend"

# Docker compose command
export DOCKERC="docker compose"

# Server connection details
export GUINETIK_SERVER="45.32.174.122"
export GUINETIK_KEY="/home/guinetik/.ssh/email@guinetik.com"

# API credentials
export GUINETIK_LOGIN="agents@guinetik.com"
export GUINETIK_PASSWORD="CCw7gI4Vwm6utc"
export GUINETIK_API_URL="https://api.guinetik.com"

# Bitwarden Secrets Manager token
export BWS_ACCESS_TOKEN="0.b6b3e709-6a95-42dc-8fd8-b36c0078dc60.JVOjV0v9CAAHDDNcV9wynr6iZo8RpX:FJj/X6sYYth7/xlSr16nag=="

# API token (generated at runtime by guinetik-login)
export GUINETIK_API_TOKEN=""

# SSH helper function
guinetikssh() {
    if [ -n "$1" ]; then
        ssh -i "$GUINETIK_KEY" "root@$GUINETIK_SERVER" "$@"
    else
        ssh -i "$GUINETIK_KEY" "root@$GUINETIK_SERVER"
    fi
}

# API login function
guinetik-login() {
  if [[ -z "$GUINETIK_LOGIN" || -z "$GUINETIK_PASSWORD" || -z "$GUINETIK_API_URL" ]]; then
    echo "⚠️  Missing one or more required environment variables:"
    echo "    GUINETIK_LOGIN, GUINETIK_PASSWORD, GUINETIK_API_URL"
    return 1
  fi

  local response token
  response=$(curl -s -X POST "$GUINETIK_API_URL/auth/login-email" \
    -H "Content-Type: application/json" \
    -d "{\\email\\:\"$GUINETIK_LOGIN\\,\\password\\:\"$GUINETIK_PASSWORD\\}")

  token=$(echo "$response" | jq -r '.token // empty')

  if [[ -n "$token" ]]; then
    export GUINETIK_API_TOKEN="$token"
    echo "✅ Login successful. Token saved to \$GUINETIK_API_TOKEN"
  else
    echo "❌ Login failed."
    echo "$response"
    return 1
  fi
}

alias guinetikapi="guinetik-login"
# END GUINETIK CONFIG

. "$HOME/.atuin/bin/env"

# EDITOR - Set by micro installer
export EDITOR=micro

# pnpm
export PNPM_HOME="/home/guinetik/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/guinetik/.bun/_bun" ] && source "/home/guinetik/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Bun - added by gui-dotfiles
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go (Golang) - added by gui-dotfiles
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
